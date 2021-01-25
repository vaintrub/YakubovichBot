FROM perl:5.20

RUN cpanm --notest --install \
        LWP::UserAgent \
        DBIx::Class \
        EV \
        Coro \
        Data::Dumper \
        Mouse \
        JSON::XS \
        Net::SSLeay \
        URI::Escape \
        AnyEvent::HTTP \
        Mouse::Role \
        Config::JSON \
        Path::Class 

WORKDIR /usr/src/YakubovichBot

ENV TOKEN ""
ENV BOT_DEBUG 0

COPY . .
CMD [ "perl", "./bin/start_ev.pl"]
