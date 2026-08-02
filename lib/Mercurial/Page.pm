package Mercurial::Page;

use Moo;

with 'Mercurial::Role::Defaults', 'MooX::Role::SEOTags';

has [qw[ path title description ]] => (
  is => 'ro',
);

sub og_title {
  'Mercurial Albums - ' . shift->title;
}

sub og_description {
  shift->description;
}

sub slug_type { '' }
sub slug_attribute { 'path' }
  
1;
