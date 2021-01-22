package Model::Schema::Result::Session;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->table('session');


__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_nullable => 0,
        is_auto_increment => 1
    },
    id_quest => {
        data_type => 'integer',
        is_nullable => 0,
    },
    id_chat => {
        data_type => 'integer',
        is_nullable => 0,
    },
    state_game => {
        data_type => 'text',
        is_nullable => 0,
    },
    max_cnt_players => {
        data_type => 'integer',
        is_nullable => 0,
    },
    cnt_players => {
        data_type => 'integer',
        is_nullable => 0,
    },
    id_current_player => {
        data_type => 'integer',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint([qw(id)]);

__PACKAGE__->belongs_to(question => 'Model::Schema::Result::Quest', {'foreign.id' => 'self.id_quest'});
__PACKAGE__->belongs_to(team => 'Model::Schema::Result::SessInfo', {'foreign.id_session' => 'self.id'}, {cascade_delete => 0});
__PACKAGE__->has_one(player => 'Model::Schema::Result::Player', {'foreign.id' => 'self.id_current_player'}, {cascade_delete => 0});

1;
