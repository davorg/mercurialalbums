use utf8;
package Mercurial::Schema::Result::Year;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Mercurial::Schema::Result::Year

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<year>

=cut

__PACKAGE__->table("year");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 year

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "year",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<year_unique>

=over 4

=item * L</year>

=back

=cut

__PACKAGE__->add_unique_constraint("year_unique", ["year"]);

=head1 RELATIONS

=head2 albums

Type: has_many

Related object: L<Mercurial::Schema::Result::Album>

=cut

__PACKAGE__->has_many(
  "albums",
  "Mercurial::Schema::Result::Album",
  { "foreign.year_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-10-02 11:23:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gKu2/50V1BjBtS2Y8r/sCA

with 'Mercurial::Role::Defaults';

sub slug_type      { 'year' }
sub slug_attribute { 'year' }

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
