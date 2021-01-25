#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Data::Dumper;

use FindBin '$Bin';
use lib "$Bin/../lib";
use TelegramClient;
use Controller;
use EV;
use Coro;
# use Coro::EV;

my $TOKEN = $ENV{TOKEN};
die "token required" unless $TOKEN;

my $t_client = TelegramClient->new(token => $TOKEN);

# warn Dumper($t_client->getWebhookInfo());
my $offset = 0;

my $timeout = 10;

my $need_stop = 0;

my $sigint_handler = AnyEvent->signal(signal => 'INT', cb => sub {
    if ($need_stop) {
        warn "Already have need_stop. Force exit";
        exit(1);
    }
    $need_stop = 1;
});

async {

    my %running_coros;

    while (!$need_stop) {
        my $updates = $t_client->getUpdates($offset, 1);
        warn("Got updates ", scalar @$updates) if $ENV{BOT_DEBUG};
        for my $update (@$updates) {

            my $timer_watcher;
            my $update_coro;
            my $timer_coro;
            $update_coro = async {
                my $ret_message;
                warn "$update_coro:", Dumper($update) if $ENV{BOT_DEBUG};
                if ($update->{message}->{text}){
                    if ($update->{message}->{text} =~ /^(\S+)\s*/i) {
                        if ($1 =~ /^якубович/i) {
                            $update->{message}->{text} =~ s/^(\S+)\s*//i;
                             $ret_message = Controller::on_message(
                                    $update->{message}->{text}, 
                                    $update->{message}->{from},
                                    $update->{message}->{chat}->{id},
                                );
                        } elsif ($1 =~ /^\/start/i || $1 =~ /^\/help/i) {
                            $ret_message = Controller::on_message('help');
                        }
                    }
                    if ($ret_message) {
                        $t_client->sendMessage($update->{message}->{chat}->{id}, $ret_message);
                    }
                }

                if ($timer_watcher) {
                    $timer_watcher = undef;
                }
                if ($timer_coro) {
                    $timer_coro->cancel();
                }

                delete $running_coros{$update_coro};
            };

            $running_coros{$update_coro} = $update_coro;
            $offset = $update->{update_id};

            warn("Srarted coro for updates: $update_coro") if $ENV{BOT_DEBUG};

            $timer_coro = async {
                $timer_watcher = AnyEvent->timer(after => $timeout, cb => Coro::rouse_cb());
                Coro::rouse_wait();
                warn("Coro timeouted ", $update_coro) if $ENV{BOT_DEBUG};
                $update_coro->cancel();
                delete $running_coros{$update_coro};
            };

        }
        $offset++ if @$updates;
        warn("Next. Current running coros:", scalar keys %running_coros) if $ENV{BOT_DEBUG};
    }

    $_->join for values %running_coros;

    EV::unloop()
};

EV::loop();
