use utf8;
package Mercurial::Schema::Result::Artist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Mercurial::Schema::Result::Artist

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<artist>

=cut

__PACKAGE__->table("artist");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 sort_name

  data_type: 'text'
  default_value: name
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "sort_name",
  { data_type => "text", default_value => \"name", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONS

=head2 albums

Type: has_many

Related object: L<Mercurial::Schema::Result::Album>

=cut

__PACKAGE__->has_many(
  "albums",
  "Mercurial::Schema::Result::Album",
  { "foreign.artist_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-10-05 15:06:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+2GoqGsuhRWxpYH4SSnv6A

with 'Mercurial::Role::Defaults', 'MooX::Role::SEOTags';

sub og_title { shift->name }

sub slug_type      { 'artist' }
sub slug_attribute { 'name' }

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
