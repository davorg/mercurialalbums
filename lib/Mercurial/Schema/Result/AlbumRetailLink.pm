use utf8;
package Mercurial::Schema::Result::AlbumRetailLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Mercurial::Schema::Result::AlbumRetailLink

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<album_retail_link>

=cut

__PACKAGE__->table("album_retail_link");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 album_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 retailer

  data_type: 'text'
  is_nullable: 0

=head2 country

  data_type: 'text'
  is_nullable: 0

=head2 asin

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "album_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "retailer",
  { data_type => "text", is_nullable => 0 },
  "country",
  { data_type => "text", is_nullable => 0 },
  "asin",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<album_id_retailer_country_unique>

=over 4

=item * L</album_id>

=item * L</retailer>

=item * L</country>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "album_id_retailer_country_unique",
  ["album_id", "retailer", "country"],
);

=head1 RELATIONS

=head2 album

Type: belongs_to

Related object: L<Mercurial::Schema::Result::Album>

=cut

__PACKAGE__->belongs_to(
  "album",
  "Mercurial::Schema::Result::Album",
  { id => "album_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-10-05 16:04:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2Gs0v/XHGIPz4mFAOiul5A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
