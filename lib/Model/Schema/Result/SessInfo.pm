package Model::Schema::Result::SessInfo;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->table('session_info');


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
    id_session => {
        data_type => 'integer',
        is_nullable => 0,
    },
    num_in_sess => {
        data_type => 'integer',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint([qw(id)]);

__PACKAGE__->has_one(session => 'Model::Schema::Result::Session', {'foreign.id' => 'self.id_session'}, {cascade_delete => 0});
__PACKAGE__->belongs_to(player => 'Model::Schema::Result::Player', {'foreign.id' => 'self.id_player'});
__PACKAGE__->has_one(player_state => 'Model::Schema::Result::PlayerStates', {'foreign.id_player' => 'self.id_player'});

1;
