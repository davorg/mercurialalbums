package Mercurial::Role::Defaults;

use strict;
use warnings;
use utf8;

use Moo::Role;
use Text::Unidecode;

requires 'slug_attribute', 'slug_type';

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

  return '/' . $self->slug_type . '/' . $self->slug;
}

1;
