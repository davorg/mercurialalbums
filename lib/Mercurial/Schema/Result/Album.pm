use utf8;
package Mercurial::Schema::Result::Album;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Mercurial::Schema::Result::Album

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<album>

=cut

__PACKAGE__->table("album");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 artist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 year_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_winner

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 blurb

  data_type: 'text'
  is_nullable: 1

=head2 sort_title

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "artist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "year_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_winner",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "blurb",
  { data_type => "text", is_nullable => 1 },
  "sort_title",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<title_artist_id_unique>

=over 4

=item * L</title>

=item * L</artist_id>

=back

=cut

__PACKAGE__->add_unique_constraint("title_artist_id_unique", ["title", "artist_id"]);

=head1 RELATIONS

=head2 album_retail_links

Type: has_many

Related object: L<Mercurial::Schema::Result::AlbumRetailLink>

=cut

__PACKAGE__->has_many(
  "album_retail_links",
  "Mercurial::Schema::Result::AlbumRetailLink",
  { "foreign.album_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 artist

Type: belongs_to

Related object: L<Mercurial::Schema::Result::Artist>

=cut

__PACKAGE__->belongs_to(
  "artist",
  "Mercurial::Schema::Result::Artist",
  { id => "artist_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "NO ACTION" },
);

=head2 year

Type: belongs_to

Related object: L<Mercurial::Schema::Result::Year>

=cut

__PACKAGE__->belongs_to(
  "year",
  "Mercurial::Schema::Result::Year",
  { id => "year_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-10-09 13:31:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4F+pCswfQf9oMoupZB3gvQ

with 'Mercurial::Role::Defaults', 'MooX::Role::SEOTags', 'MooX::Role::JSON_LD';

sub slug_type      { 'album' }
sub slug_attribute { 'title' }

sub og_title {
  'Mercurial Albums - Album: ' . shift->title;
};

sub amazon_asin {
  my $self = shift;

  my $asin = $self->album_retail_links->search({
    retailer => 'amazon',
    country  => 'GB',
  })->first;

  return unless $asin;

  return $asin->asin;
}

sub json_ld_type { 'MusicAlbum' }

sub json_ld_fields {
  my $self = shift;
  return [
    { name => 'title' },
    { '@id' => sub { $self->og_url . '#album' } },
    { url => sub { $self->og_url } },
    { datePublished => sub { $self->year->year . '' } },
    { byArtist => sub { $_[0]->artist->json_ld_data } },
    { mainEntityOfPage => sub { $self->og_url } },
  ];
}

sub json_ld_short_data {
  my $self = shift;

  return {
    '@type'  => $self->json_ld_type,
    name     => $self->title,
    byArtist => {
      '@type' => 'MusicGroup',
      name    => 'Various Artists',
      url     => $self->og_url,
    }
  }
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
