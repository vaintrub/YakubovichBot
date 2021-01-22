package Game;
use Mouse;
use utf8;
extends 'Session';
has quest => (is => 'ro', isa => 'Str', lazy_build => 1);
has answer => (is => 'ro', isa => 'Str', lazy_build => 1);
has state_game => (is => 'rw', isa => 'Str', lazy_build => 1, trigger => sub {
                my ($self, $nv, $ov) = @_;    
                $self->dbh->resultset('Session')->find($self->id_session)->update({state_game => $nv});
            });
before 'delete_session' => \&initialize_session;
before 'team_players_to_string' => \&initialize_session;
before 'check_answer' => \&initialize_session;
around 'check_answer' => \&next_turn; 
no Mouse;

sub initialize_session {
    my $self = shift;
    return if $self->id_session;
    my $session = $self->dbh->resultset('SessInfo')->search(
            {
                'session.id_chat' => $self->id_chat,
                'me.id_player' => $self->id,
            },
            {
                prefetch => 'session',
            }
        )->single;
    $self->id_session($session->session->id);
    $self->state_game($session->session->state_game);
    $self->set_players;
}
sub next_turn {
    my $orig = shift;
    my $self = shift;
    my $dbh = $self->dbh;
    my $res;
    return $res if ($res = $self->validate_turn);
    my $text = shift;
    $res = $self->$orig($text);
    if ($self->state_game eq $self->answer) {
        $self->delete_session;
        my $rs_rating = $dbh->resultset('Rating');
        if (my $self_player = $rs_rating->find({id_player => $self->id})) {
            my $score = $self_player->cnt_wins; 
            $self_player->update({cnt_wins => ++$score});
        } else {
            $rs_rating->create({
                        id_player => $self->id,
                        cnt_wins => 1,
                        id_chat => $self->id_chat,
                });
        }
        $res .= "\n".$self->first_name.", молодец ты выиграл!!";
    } else {
        my $players = $self->team_players;
        if ($res) {
            $self->change_current_player;
            $res .= "Теперь ходит: ". $players->{$self->curr_num_in_sess}->{username}; 
        } else {
            $res .= $self->state_game . "\n" . " Пробуй еще!";
        }
    }
    return $res;
}

sub validate_turn {
    my $self = shift;
    my $curr_player = $self->dbh->resultset('Session')->find($self->id_session)->player;
    return "Сейчас не твой ход! Ходит: ".$curr_player->username ."\n" if ($self->id != $curr_player->id);
}
sub _build_quest {
    my $self = shift;
    $self->dbh->resultset('Session')->find($self->id_session)->question->quest;
}
sub _build_state_game {
    my $self = shift;
    $self->dbh->resultset('Session')->find($self->id_session)->state_game;
}
sub _build_answer {
    my $self = shift;
    lc $self->dbh->resultset('Session')->find($self->id_session)->question->answer;
}

sub check_answer {
    my ($self, $text) = @_;
    $text = lc $text;
    my $state_game = $self->state_game;
    my $answer = $self->answer;
    if (length($text) == 1) {
        if (index($answer, $text) == -1) {
            return $self->first_name . ": Не-а, здесь нет такой буквы.\n";
        } else {
            my $index = index($answer, $text);
            my $ind = $index;
            my $substr =substr($answer, 0,length $answer);
            while ($index != -1) {
                substr($state_game, $ind, 1, $text);
                $substr = substr($substr, $index+1,(length $substr) - $index);   
                $index = index($substr, $text);
                $ind += $index + 1;
            }
            $self->state_game($state_game);
            return undef;
        }
    } elsif (length($text) == length($answer)) {
        if($text eq $answer){
            $self->state_game($answer);
        }else{
            return $self->first_name . ": Неправильное слово!\n";
        }
    } else {
        return $self->first_name . ": Неправильное слово!\n";
    }
}

__PACKAGE__->meta->make_immutable();
