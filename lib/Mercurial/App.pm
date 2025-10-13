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
    title    => 'Mercurial Albums — Mercury Prize shortlists and winners',
    description => 'Mercurial Albums — Mercury Prize shortlists and winners',
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
  open my $fh, '>:encoding(UTF-8)', $path or die "write $path: $!";
  $tt->process($args{template}, $args{vars}, $fh) or die $tt->error;
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
  $self->write_page(
    template => 'home.tt',
    vars     => { page => $page },
    path     => ['index.html'],
  );
  push @urls, $page->og_url;

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
