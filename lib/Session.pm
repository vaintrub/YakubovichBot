package Session;
use constant PREPARING => 1;
use constant WAITING => 2;
use constant PLAYING => 3;
use utf8;
use Mouse;
has id_session => (is => 'rw', isa => 'Int');
has id_chat => (is => 'ro', isa => 'Int', required => 1);
has team_players => (is => 'rw', isa => 'HashRef');
has curr_num_in_sess => (is => 'rw', isa => 'Int');
has cnt_players => (is => 'rw', isa => 'Int');
has max_cnt_players => (is => 'rw', isa => 'Int');
no Mouse;

sub create_session {
    my ($self, $max_cnt_players) = @_;
    my $dbh = $self->dbh;
    # Get random question
    my $inf_quest = $dbh->storage->dbh_do( # TODO keep 5 previous questions from people
        sub { 
            my ($storage, $dbh, @cols) = @_;
            $dbh->selectrow_hashref("SELECT * FROM questions WHERE _ROWID_ >= (abs(random()) % (SELECT max(_ROWID_) FROM questions))
                                                               LIMIT 1;");
        }
    );
    my $state = $inf_quest->{answer};
    $state =~ s/\w/\*/g;
    my $sess = $dbh->resultset('Session')->create({
                id_quest => $inf_quest->{id},
                id_chat => $self->id_chat,
                state_game => $state,
                max_cnt_players => $max_cnt_players,
                cnt_players => 1,
                id_current_player => $self->id,
        });
    $dbh->resultset('SessInfo')->create({
            id_session => $sess->id,
            id_player => $self->id,
            num_in_sess => 1,
        });
    $self->team_players({1 => {username => $self->username, id => $self->id}});
    $self->id_session($sess->id);
    return;
}
sub find_sessions {
    my $self = shift;
    my $dbh = $self->dbh;
    my @sessions = $dbh->resultset('Session')->search({id_chat => $self->id_chat, cnt_players => {'<' => {-ident => 'max_cnt_players'}}});
    my $list_sess = sprintf("%-25s%-20s", "ID игры:", "Кол. человек:");
    for (@sessions) {
        $list_sess .= "\n";
        $list_sess .= sprintf("%-30s[%-d/%-d]", $_->id, $_->cnt_players, $_->max_cnt_players);
    }
    return $list_sess;
}
sub connect_to_session {
    my ($self, $id_sess) = @_;
    my $session = $self->dbh->resultset('Session')->find($id_sess);
    if ($session) {
        my @team = $self->dbh->resultset('SessInfo')->search({id_session => $id_sess});
        my $cnt_players = @team;
        my $max_cnt_players = $session->max_cnt_players;
        if ($cnt_players < $max_cnt_players) {
            $cnt_players++;
            $session->update({cnt_players => $cnt_players});
            $self->dbh->resultset('SessInfo')->create({
                    id_player => $self->id,
                    id_session => $id_sess,
                    num_in_sess => $cnt_players,
                });
            my $team;
            $team->{$_->num_in_sess} = {username => $_->player->username, id => $_->id_player} for (@team);
            $team->{$cnt_players} = {username => $self->username, id => $self->id};
            $self->team_players($team);
            $self->cnt_players($cnt_players);
            $self->max_cnt_players($max_cnt_players);
            $self->id_session($id_sess);
            return 1;
        } else {
            return undef;
        }
    } else {
        return undef;
    }
}
sub delete_session {
    my $self = shift;
    my $dbh = $self->dbh;
    my @sess_players =  $dbh->resultset('SessInfo')->search({id_session => $self->id_session}); 
    # TODO cascade delete
    for (@sess_players) {
        $_->player_state->update({state => PREPARING});
        $_->delete;
    }
    $dbh->resultset('Session')->find($self->id_session)->delete;
}
sub team_players_to_string {
    my $self = shift;
    my $string = "Игроки:";
    my %team = %{ $self->team_players };
    for my $num_in_sess (sort keys %team) {
        $string .= "\n";
        $string .= sprintf("%d) %s", $num_in_sess, $team{$num_in_sess}->{username}); 
    }
    return $string;
}
sub change_current_player {
    my $self = shift;
    my $rs_session = $self->dbh->resultset('Session')->find($self->id_session);
    my $num_in_sess = $self->curr_num_in_sess;
    my $players = $self->team_players;
    if ($players->{++$num_in_sess}) {
        $rs_session->update({id_current_player => $players->{$num_in_sess}->{id}});
        $self->curr_num_in_sess($num_in_sess);
    } else {
        $rs_session->update({id_current_player => $players->{1}->{id}});
        $self->curr_num_in_sess(1);
    }
}
sub set_players {
    my $self = shift;
    my %players;
    my @players = $self->dbh->resultset('SessInfo')->search({id_session => $self->id_session});
    for my $player (@players) {
        $self->curr_num_in_sess($player->num_in_sess) if $player->id_player == $self->id;
        $players{$player->num_in_sess} = {username => $player->player->username, id => $player->id_player};
    }
    $self->team_players(\%players);
}

sub get_rating {
    my $self = shift;
    my @players = $self->dbh->resultset('Rating')->search(
            {'me.id_chat' => $self->id_chat},
            {
                order_by => {-desc => [qw(me.cnt_wins)]},
                prefetch => 'player'
            },
        ); 
    my $rating = sprintf("%-30s%-25s", "Имя:", "Кол. побед:");
    for (0..$#players) {
        $rating .= "\n";
        $rating .= sprintf("%-25s%-d", $players[$_]->player->username, $players[$_]->cnt_wins);
    }
    return $rating;
}


__PACKAGE__->meta->make_immutable();
