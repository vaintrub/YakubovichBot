package Player;
use constant PREPARING => 1;
use constant WAITING => 2;
use constant PLAYING => 3;
use utf8;
use Mouse;
extends 'Game';
with 'Role::HasDBH';
has id => (is => 'ro', isa => 'Int', required => 1);
has first_name => (is => 'ro', isa => 'Str', required => 1);
has last_name => (is => 'ro', isa => 'Str');
has username => (is => 'ro', isa => 'Str');
has state => (is => 'rw', isa => 'Int', trigger => \&_trigger_state);
no Mouse;
sub _trigger_state {
    my ($self, $nv, $ov) = @_;
    my $rs_states = $self->dbh->resultset('PlayerStates');
    if (defined $ov) { # Change state
        # TODO add search to DBIx result class
        $rs_states->search({
                id_player => $self->id, 
                id_chat => $self->id_chat, 
            })->single->update({state => $nv});
    }
}
sub BUILDARGS {
    my ($class, %args) = @_;
    $args{username} = '@'. ($args{username} || $args{first_name});
    return \%args;
}
sub BUILD {
    my $self = shift;
    my $dbh = $self->dbh;
    my $rs_players = $dbh->resultset('Player');
    my $rs_states = $dbh->resultset('PlayerStates');
    #TODO add expiration time
    if (my $player = $rs_players->find($self->id)) {
        my $state;
        unless ($state = $player->states->find({id_chat => $self->id_chat})) {    
            $state = $rs_states->create({
                id_player => $self->id,
                id_chat => $self->id_chat,
                state => PREPARING,
            });
        }
        $self->state($state->state); 
    } else { # Add a player to the database if he was not there 
         $rs_players->create({
                id => $self->id,
                first_name => $self->first_name,
                last_name => $self->last_name,
                username => $self->username,
            }); 
        $rs_states->create({
                id_player => $self->id,
                id_chat => $self->id_chat,
                state => PREPARING,
            });
        $self->state(PREPARING);
    }
    return;
}

__PACKAGE__->meta->make_immutable();
