package Mercurial::Role::Defaults;

use strict;
use warnings;
use utf8;

use Moo::Role;
use Text::Unidecode;

requires 'slug_attribute', 'slug_type';

sub domain {
  return 'https://mercurialalbums.com';
}

sub og_image {
  my $self = shift;

  return $self->domain . '/assets/mercury_og.png';
}

sub og_description {
  shift->og_title;
}

sub og_url {
  my $self = shift;

  my $url_path = $self->url_path;

  if ($url_path !~ /\.\w+$/ and $url_path !~ m|/$|) {
    $url_path .= '/';
  }

  return $self->domain . $url_path;
}

sub og_type { 'website' }

sub slug {
  my $self = shift;

  my $slug_attribute = $self->slug_attribute;
  my $slug = lc $self->$slug_attribute;

  # special case - thanks Ed!
  return 'divide' if $slug eq '÷';

  $slug //= '';
  $slug = unidecode($slug);
  $slug =~ s/['’]//g;
  $slug =~ s/[^Za-z0-9]+/-/g;
  $slug =~ s/-+/-/g;
  $slug =~ s/^-|-$//g;

  return $slug;
}

sub url_path {
  my $self = shift;

  my $path = '/';
  $path .= $self->slug_type . '/' if $self->slug_type;
  $path .= $self->slug if $self->slug;

  return $path;
}

1;
