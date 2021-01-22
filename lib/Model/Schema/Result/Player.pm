package Model::Schema::Result::Player;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->table('players');

__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_nullable => 0,
        is_auto_increment => 0
    },
    first_name => {
        data_type => 'text',
        is_nullable => 0,
    },
    last_name => {
        data_type => 'text',
        is_nullable => 1
    },
    username => {
        data_type => 'text',
        is_nullable => 1
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint([qw(id)]);

__PACKAGE__->belongs_to(rating => 'Model::Schema::Result::Rating', {'foreign.id_player' => 'self.id'});
__PACKAGE__->has_many(session_info => 'Model::Schema::Result::SessInfo', {'foreign.id_player' => 'self.id'});
__PACKAGE__->has_many('states' => 'Model::Schema::Result::PlayerStates', {'foreign.id_player' => 'self.id'});
__PACKAGE__->belongs_to(session => 'Model::Schema::Result::Session', {'foreign.id_current_player' => 'self.id'});

1;
