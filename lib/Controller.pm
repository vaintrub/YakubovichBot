package Controller;

use warnings;
use strict;
use feature 'say';

use lib '.';
use Player;
use utf8;
use Data::Dumper;

use constant PREPARING => 1;
use constant WAITING => 2;
use constant PLAYING => 3;
my %STATES = (
        PREPARING() => \&prepare_process,
        WAITING() => \&waiting_process,
        PLAYING() => \&playing_process,
    );

sub on_message {
    my ($msg, $from, $id_chat) = @_;
    return "Со мной можно поиграть в поле чудес!\nДоступные команды:\n1) [ Якубович начинай ] - начать игру\n2) [ Якубович рейтинг ] - Посмотреть рейтинг игроков этого чата." if $msg =~ /^\s*help\s*$/i;
    my $player = Player->new(
        id => $from->{id},
        first_name => $from->{first_name},
        last_name => $from->{last_name},
        username => $from->{username},
        id_chat => $id_chat,
    );
    return $player->get_rating if $msg =~ /^\s*рейтинг\s*$/i;
    my $state_handler = $STATES{$player->state};
    return $state_handler->($player, $msg);
}
sub prepare_process {
    my ($player, $msg) = @_;
    if ($msg =~ /^\s*начинай\s*$/i) {
        my $res = "1) [ Якубович новая игра <n> ] - создать новую игру (n: кол-во участников)\n"; 
        $res .= "2) [ Якубович игра <id> ] - Присоединиться к доступной игре(id игры)\n\n";
        $res .= "Список доступных игр:\n";
        $res .= $player->find_sessions;
        return $res;
    } elsif ($msg =~ /^\s*новая\s+игра\s+(\d+)\s*$/i) {
        $player->create_session($1);
        my $res = $player->first_name.", ваша игра: [ id - " . $player->id_session . " ], [ Участников - 1/$1 ]\n\n";
        if ($1 == 1) {
            $res .= "Игра началась!\n";
            $res .= $player->team_players_to_string . "\n\n";
            $res .= "Вопрос: ".$player->quest . "\n\n";
            $res .= "Слово: ".$player->state_game;
            $player->state(PLAYING);
            return $res;
        }
        $res .= "Ожидание игроков...\n";
        $player->state(WAITING);
        return $res;
    } elsif ($msg =~ /^\s*игра\s+(\d+)\s*$/i) {
        return $player->first_name.", такой игры нет, либо там уже нет мест. Выбери другую" unless $player->connect_to_session($1);
        my $res = $player->first_name.", вы подключились к игре [id - " .$player->id_session." ], [ Участников - " . $player->cnt_players."/".$player->max_cnt_players." ]\n";
        if ($player->cnt_players == $player->max_cnt_players) {
            $res .= "Игра началась!\n";
            $res .= $player->team_players_to_string."\n\n";
            $res .= "Вопрос: ".$player->quest . "\n\n";
            $res .= "Слово: ".$player->state_game;
            $player->state(PLAYING);
            my %team = %{ $player->team_players };
            for (keys %team) {
                $player->dbh->resultset('PlayerStates')->search({
                        id_player => $team{$_}->{id},
                        id_chat => $player->id_chat,
                    })->single->update({state => PLAYING});
            }
            return $res;
        }
        $res .= "Ожидание игроков...\n";
        $player->state(WAITING);
        return $res;
    } else {
        #TODO Ты не играешь
        return "Ты еще не играешь!\nЧтобы посмотреть список доступных команд пиши: [Якубович help]";
    }
}
sub waiting_process {
    my ($player, $msg) = @_;
    my $res;
    if ($msg =~ /^\s*отключиться\s*$/i) {
        $res = $player->username.", покинул эту сессию(\n"; 
        $res .= "Игроки были распущены:\n";
        $res .= $player->team_players_to_string;
        $res .= "\nСессия удалена.";
        $player->delete_session;
        return $res;
    } else {
        $res .= "Вы в ожидании игры\n";
        $res .= "Можно отключится написав [ Якубович отключиться ]\n";
        return $res; 
    }
}
sub playing_process {
    my ($player, $msg) = @_;

    if ($msg =~ /^\s*буква\s+(\w)\s*$/i) {
        $player->check_answer($1);
    } elsif ($msg =~ /^\s*слово\s+(\w+)\s*$/i){
        $player->check_answer($1);
    } else {
        my $res = $player->first_name.", вы находитесь в процессе игры!\n";
        $res .= "Доступные команды в этом режиме:\n";
        $res .= "1) Якубович слово ...\n";
        $res .= "1) Якубович буква ...\n";
        return $res;
    }
}

1;
