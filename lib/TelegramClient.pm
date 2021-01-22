package TelegramClient;
use utf8;

use LWP::UserAgent;
use JSON::XS;
use Net::SSLeay;
use Data::Dumper;
use URI::Escape;
use Coro;
use AnyEvent::HTTP;

use Mouse;
has ua => (is => 'ro', isa => 'LWP::UserAgent', required => 1);
has host => (is => 'ro', isa => 'Str', required => 1);
has token => (is => 'ro', isa => 'Str', required => 1);
no Mouse;

sub BUILDARGS {
    my ($class, %args) = @_;
    #All queries to the Telegram Bot API must be served over HTTPS and need to be presented in this form: https://api.telegram.org/bot<token>/METHOD_NAME
    $args{ua} = LWP::UserAgent->new(agent => 'Yakubovich');
    $args{host} = 'https://api.telegram.org/bot' . $args{token} . '/';
    return \%args;
}

sub getUpdates {
    my ($self, $offset, $timeout) = @_;
    return $self->_request('getUpdates', 'GET', {offset => $offset, timeout => $timeout, allowed_updates => "[]"});
}

sub sendMessage {
    my ($self, $chat_id, $text) = @_;
    if (length($text) > 1024) {
        $text = substr($text,0,1024);
    }
    return $self->_request('sendMessage', 'GET', {chat_id => $chat_id, text => $text});
}

sub getWebhookInfo {
    return $_[0]->_request('getWebhookInfo', 'GET');
}

sub _request {
    my ($self, $method, $type, $data) = @_;
    my $url = $self->host . $method;
    my ($body, $hdr);
    if ($type eq 'GET') {
        my $params = join "&", map {$_ . "=" . uri_escape_utf8($data->{$_})} keys %$data;
        $url .= $url =~ /\?/ ? '&' . $params  : '?' . $params;
        warn "URL: $url" if $ENV{BOT_DEBUG};
        http_get($url, Coro::rouse_cb());
        ($body, $hdr) = Coro::rouse_wait();
    } elsif ($type eq 'POST') {
        die "Not implemented";
    } else {
        die "Unknown type `$type`"
    }
    if ($hdr->{Status} =~ /^2/) {
        my $ret = JSON::XS::decode_json($body);
        if ($ret->{ok}) {
            return $ret->{result};
        } else {
            warn "Error comunicate with telegram", Dumper($ret);
        }
    }
    else {
        die Dumper($body, $hdr);
    }
}

__PACKAGE__->meta->make_immutable();
