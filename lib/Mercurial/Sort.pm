package Mercurial::Sort;

use strict;
use warnings;
use utf8;

use Exporter 'import';

our @EXPORT_OK = qw(sort_value);

sub sort_value {
  my ($value) = @_;

  return undef unless defined $value;

  $value =~ s/^\s+|\s+$//g;
  $value =~ s/\s+/ /g;
  $value =~ s/^(?:a|an|the)\s+//i;

  return lc $value;
}

1;
