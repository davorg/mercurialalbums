use strict;
use warnings;

use Test::More;
use DBI;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use IPC::Open3;
use Symbol qw(gensym);

my $root = File::Spec->rel2abs("$Bin/..");
my $script = "$root/bin/set_winner";
my $tmp = tempdir(CLEANUP => 1);
my $db = "$tmp/catalogue.db";
my $dbh = DBI->connect("dbi:SQLite:$db", '', '', {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});
open my $schema_fh, '<', "$root/db/mercurial.sql" or die $!;
my $sql = do { local $/; <$schema_fh> };
close $schema_fh;
$dbh->do($_) for grep /\S/, split /;/, $sql;
$dbh->do("INSERT INTO year (id, year, winner_announcement_date) VALUES (1, 2025, NULL), (2, 2026, '2026-10-22')");
$dbh->do("INSERT INTO artist (id, name, sort_name, blurb) VALUES (1, 'Artist One', 'artist one', 'Biography'), (2, 'Artist Two', 'artist two', 'Another biography')");
$dbh->do("INSERT INTO album (id, title, artist_id, year_id, is_winner, blurb, sort_title, cover_filename, cover_source_url) VALUES (10, 'Earlier Album', 1, 1, 1, 'Notes', 'earlier album', 'earlier.jpg', 'https://example.test/earlier.jpg'), (11, 'First Album', 1, 2, 0, 'Notes', 'first album', 'first.jpg', 'https://example.test/first.jpg'), (12, 'Second Album', 2, 2, 0, 'Notes', 'second album', 'second.jpg', 'https://example.test/second.jpg')");
$dbh->do("INSERT INTO album_retail_link (album_id, retailer, country, link_type, asin) VALUES (11, 'amazon', 'GB', 'product', 'EXAMPLE')");

sub run_command {
  my (@args) = @_;
  my $stderr = gensym;
  my $pid = open3(my $in, my $out, $stderr, $^X, $script, @args);
  close $in;
  my $stdout_text = do { local $/; <$out> } // '';
  my $stderr_text = do { local $/; <$stderr> } // '';
  waitpid $pid, 0;
  return ($? >> 8, $stdout_text, $stderr_text);
}

sub run { run_command('--db', $db, @_) }
sub flags { $dbh->selectall_arrayref('SELECT id, is_winner FROM album ORDER BY id') }
sub content {
  return [
    $dbh->selectall_arrayref('SELECT id, title, artist_id, year_id, blurb, sort_title, cover_filename, cover_source_url FROM album ORDER BY id'),
    map { $dbh->selectall_arrayref("SELECT * FROM $_ ORDER BY id") }
      qw(artist year album_retail_link),
  ];
}
my $original_content = content();

subtest 'list without changing data' => sub {
  my $before = flags();
  my ($status, $out, $err) = run(2026);
  is $status, 0, 'listing succeeds';
  like $out, qr/11\s+Artist One.*First Album/, 'first shortlisted album and ID';
  like $out, qr/12\s+Artist Two.*Second Album/, 'second shortlisted album and ID';
  unlike $out, qr/Earlier Album/, 'other years excluded';
  is $err, '', 'no errors';
  is_deeply flags(), $before, 'winner flags unchanged';
};

subtest 'set, change, and repeat winner' => sub {
  my ($status, $out) = run(2026, 11);
  is $status, 0, 'setting the first winner succeeds';
  like $out, qr/Set 2026 winner: Artist One.*First Album/, 'names the selected winner';
  is_deeply flags(), [[10, 1], [11, 1], [12, 0]], 'only the selected year changes';
  is((run(2026, 12))[0], 0, 'changing the winner succeeds');
  is_deeply flags(), [[10, 1], [11, 0], [12, 1]], 'old winner cleared';
  is((run(2026, 12))[0], 0, 'repeating the same command succeeds');
  is_deeply flags(), [[10, 1], [11, 0], [12, 1]], 'repeated selection remains the sole winner';
  like((run(2026))[1], qr/Second Album \[winner\]/, 'listing marks the current winner');
};

subtest 'invalid selections preserve the current winner' => sub {
  my $before = flags();
  for my $case ([2026, 10], [2026, 999], [2027, 11], ['invalid', 11], [2026, 'oops'], [2026, 0], []) {
    my ($status) = run(@$case);
    isnt $status, 0, 'invalid input fails: ' . join(' ', @$case);
    is_deeply flags(), $before, 'winner flags preserved';
  }
};

subtest 'transaction rolls back if setting the new winner fails' => sub {
  my $before = flags();
  $dbh->do("CREATE TRIGGER reject_winner BEFORE UPDATE OF is_winner ON album WHEN NEW.id=11 AND NEW.is_winner=1 BEGIN SELECT RAISE(ABORT, 'test refusal'); END");
  my ($status) = run(2026, 11);
  isnt $status, 0, 'database error is reported';
  is_deeply flags(), $before, 'clearing the previous winner was rolled back';
};

subtest 'missing and empty databases are rejected' => sub {
  my $missing = "$tmp/missing.db";
  isnt((run_command('--db', $missing, 2026, 11))[0], 0, 'missing database fails');
  ok !-e $missing, 'missing database is not created';
  my $empty = "$tmp/empty.db";
  open my $fh, '>', $empty or die $!;
  close $fh;
  isnt((run_command('--db', $empty, 2026, 11))[0], 0, 'empty database fails');
  is -s $empty, 0, 'empty database is unchanged';
};

is_deeply content(), $original_content, 'all enriched data and other tables preserved';
is((run_command('--help'))[0], 0, 'help succeeds without a database argument');
done_testing;
