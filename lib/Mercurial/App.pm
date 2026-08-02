use v5.40;
use strict;
use warnings;
use feature 'class';
no warnings 'experimental::class';

class Mercurial::App;

use utf8;
use feature 'say';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use File::Path qw(make_path);
use File::Spec;
use Template;
use Time::Piece;
use Mercurial::Schema;
use Mercurial::Page;

field $db     :param = "$Bin/../db/mercurial.db";
field $out    :param = 'docs';
field $schema :param = Mercurial::Schema->get_schema($db);
field %site          = (
  title      => 'Mercurial Albums',
  base_url   => '/',
  nav => [
    { href => '/',        label => 'Home' },
    { href => '/year/',   label => 'Years' },
    { href => '/artist/', label => 'Artists' },
    { href => '/album/',  label => 'Albums' },
  ],
);

field $tt    :param = Template->new({
  INCLUDE_PATH => "$Bin/../tt_lib",
  PRE_PROCESS  => [ 'utils.tt' ],
  ENCODING     => 'utf8',
  WRAPPER      => 'layout.tt',
  VARIABLES    => \%site,
});

field %pages = (
  index => {
    path => '',
    title       => 'Mercury Prize shortlists and winners',
    description => 'Explore every Mercury Prize shortlist, nominated album and winner from 1992 to today.',
  },
  years => {
    path => 'year/',
    title    => 'Years',
    description => 'The years of the Mercury Prize',
  },
  artists => {
    path => 'artist/',
    title    => 'Artists',
    description => 'Every artist that has been nominated for a Mercury Prize',
  },
  albums => {
    path => 'album/',
    title    => 'Albums',
    description => 'Every album that has been nominated for a Mercury Prize',
  },
  about => {
    path => 'about/',
    title => 'About this site',
    description => 'About Mercurial Albums',
  },
  contact => {
    path => 'contact/',
    title => 'Contact',
    description => 'Contact me about the site',
  },
  privacy => {
    path => 'privacy/',
    title => 'Privacy policy',
    description => 'Our privacy policy',
  },
  404 => {
    path => '404.html',
    title => 'Page Not Found',
    description => '404 - page not found',
  },
);

field @urls;

method write_page {
  my (%args) = @_;
  my $path = File::Spec->catfile($out, @{$args{path}});
  my (undef,$dir,undef) = File::Spec->splitpath($path);
  make_path($dir) unless -d $dir;
  my $output = '';
  $tt->process($args{template}, $args{vars}, \$output) or die $tt->error;

  $output =~ s/\A\s+(?=<!doctype)//;
  $output =~ s/[ 	]+$//mg;
  # Keep generated head markup stable across HTML serializer versions.
  $output =~ s{<meta content="([^"<>]*)" name="([^"<>]*)">}{<meta name="$2" content="$1">}g;
  $output =~ s{<meta content="([^"<>]*)" property="([^"<>]*)">}{<meta property="$2" content="$1">}g;
  $output =~ s{<link href="([^"<>]*)" rel="canonical">}{<link rel="canonical" href="$1">}g;

  open my $fh, '>:encoding(UTF-8)', $path or die "write $path: $!";
  print {$fh} $output;
  close $fh;
# say "Wrote $path";
}

method make_sitemap {

  my $date = localtime->ymd;

  my $sitemap = "$out/sitemap.xml";

  open my $sitemap_fh, '>', $sitemap
    or die "[$sitemap] $!\n";

  print $sitemap_fh qq[<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n];

  for ( @urls ) {
    $_ .= '/' unless m|/$|;

    print $sitemap_fh <<EOF_URL;
  <url>
    <loc>$_</loc>
    <lastmod>$date</lastmod>
  </url>
EOF_URL
  }

  print $sitemap_fh "</urlset>\n";
}

method run {
  binmode STDOUT, ':encoding(UTF-8)';
  binmode STDERR, ':encoding(UTF-8)';

  # Home
  my $page = Mercurial::Page->new($pages{index});
  my $latest_year = $schema->resultset('Year')->search(
    {},
    { order_by => { -desc => 'year' }, rows => 1 },
  )->single;
  my @latest_albums = $latest_year->albums_rs->search(
    {},
    { order_by => 'sort_title' },
  )->all;
  $self->write_page(
    template => 'home.tt',
    vars     => {
      page               => $page,
      latest_year        => $latest_year,
      latest_albums      => \@latest_albums,
      latest_album_count => $latest_year->albums_rs->count,
    },
    path     => ['index.html'],
  );
  push @urls, $page->og_url;

  for (qw[about contact privacy]) {
    $page = Mercurial::Page->new($pages{$_});
    $self->write_page(
      template => "$_.tt",
      vars     => { page => $page },
      path     => [ $_, 'index.html' ],
    );
    push @urls, $page->og_url;
  }

  # 404
  $page = Mercurial::Page->new($pages{404});
  $self->write_page(
    template => '404.tt',
    vars     => { page => $page },
    path     => ['404.html'],
  );

  # Years
  $page = Mercurial::Page->new($pages{years});
  my @years = $schema->resultset('Year')->search({}, { order_by => { -desc => 'year' } })->all;
  $self->write_page(
    template => 'years_index.tt',
    vars     => { page => $page, years => \@years },
    path     => ['year','index.html'],
  );
  push @urls, $page->og_url;

  for my $yr (@years) {
    $self->write_page(
      template => 'year.tt',
      vars     => { year => $yr },
      path     => ['year', $yr->slug, 'index.html'],
    );
    push @urls, $yr->og_url;
  }

  # Artists
  $page = Mercurial::Page->new($pages{artists});
  my @artists = $schema->resultset('Artist')->sorted_artists->all;
  $self->write_page(
    template => 'artists_index.tt',
    vars     => { page => $page, artists => \@artists },
    path     => ['artist','index.html'],
  );
  push @urls, $page->og_url;

  for my $ar (@artists) {
    $self->write_page(
      template => 'artist.tt',
      vars     => { artist => $ar },
      path     => ['artist', $ar->slug, 'index.html'],
    );
    push @urls, $ar->og_url;
  }

  # Albums
  $page = Mercurial::Page->new($pages{albums});
  my @albums = $schema->resultset('Album')->by_title;
  $self->write_page(
    template => 'albums_index.tt',
    vars     => { page => $page, albums => \@albums },
    path     => ['album','index.html'],
  );
  push @urls, $page->og_url;

  for my $al (@albums) {
    $self->write_page(
      template => 'album.tt',
      vars     => {
        album => $al,
      },
      path     => ['album', $al->slug, 'index.html'],
    );
    push @urls, $al->og_url;
  }

  $self->make_sitemap();

  say "Output in '$out/'";
}
