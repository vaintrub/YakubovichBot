package Model::Schema::Result::Rating;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->table('rating');


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
    cnt_wins => {
        data_type => 'integer',
        is_nullable => 0,
    },
    id_chat => {
        data_type => 'blob',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint([qw(id)]);

__PACKAGE__->has_one(player => 'Model::Schema::Result::Player', {'foreign.id' => 'self.id_player'});

1;
