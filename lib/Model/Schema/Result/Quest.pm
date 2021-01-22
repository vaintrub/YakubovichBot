package Model::Schema::Result::Quest;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->table('questions');


__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_nullable => 0,
        is_auto_increment => 1
    },
    quest => {
        data_type => 'text',
        is_nullable => 0,
    },
    answer => {
        data_type => 'text',
        is_nullable => 0,
    }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint([qw(id)]);

__PACKAGE__->has_many(sessions => 'Model::Schema::Result::Session', {'foreign.id_quest' => 'self.id'});

1;
