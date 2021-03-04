package Model::Schema::Result::PlayerStates;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->table('player_states');


__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_nullable => 0,
        is_auto_increment => 1
    },
    id_player => {
        data_type => 'integer',
        is_nullable => 0,
    },
    id_chat => {
        data_type => 'integer',
        is_nullable => 0,
    },
    state => {
        data_type => 'integer',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint([qw(id)]);

__PACKAGE__->belongs_to(player => 'Model::Schema::Result::Player', {'foreign.id' => 'self.id_player'});
__PACKAGE__->belongs_to(sessinfo => 'Model::Schema::Result::SessInfo', {'foreign.id_player' => 'self.id_player'}, {cascade_delete => 0});

1;
