package Mercurial::Schema::ResultSet::Album;

use Moose;
use MooseX::NonMoose;

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }

sub sorted_albums {
  my $self = shift;

  return $self->search(undef, { order_by => [ { '-desc' => 'is_winner' }, 'title' ] });

}

sub by_title {
  my $self = shift;

  return $self->search(undef, { order_by => 'sort_title' });
}

sub by_year {
  my $self = shift;

  return $self->search(undef, {
    join => 'year',
    order_by => 'year.year',
  });
}

__PACKAGE__->meta->make_immutable;

1;
