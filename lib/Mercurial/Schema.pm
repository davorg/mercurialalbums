use utf8;
package Mercurial::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_components("Schema::ResultSetNames");

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-10-02 11:23:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pOWgjceFINXEcEWa4ie2fQ

use DBD::SQLite::Constants ':dbd_sqlite_string_mode';

sub get_schema {
  my $class = shift;

  my $db = shift || 'db/mercurial.db';

  my $schema =  $class->connect("dbi:SQLite:$db", {
    sqlite_unicode => 1,
    on_connect_call => 'use_foreign_keys',
  });

  my $dbh = $schema->storage->dbh;

  $dbh->{sqlite_string_mode} = DBD_SQLITE_STRING_MODE_UNICODE_FALLBACK;

  return $schema;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
