#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::UserAgent;
use DBI;
use utf8;
use feature 'say';
use Data::Dumper;
binmode(STDOUT,':utf8');
my $dbfile = "database.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","", {
        RaiseError     => 1,
        sqlite_unicode => 1,
    });
my $sth = $dbh->prepare("INSERT INTO questions (quest, answer) VALUES (?, ?)");

my $URL = "http://otvety-pole-chudes.biniko.com/";
my $ua = Mojo::UserAgent->new;
my $dom = $ua->get($URL."otvety_pole_chudes.php")->res->dom;

for my $a ($dom->find('div[id="content_otvet"] a')->each) {
    my $question = $a->text;
    my $ua2 = Mojo::UserAgent->new;
    my $dom2 = $ua2->get($URL.$a->{href})->res->dom;
    my $answer = $dom2->at('p.otvet')->text;
    chomp($question);
    chomp($answer);
    $question =~ s/^\s+|\s+$//;
    $question .= '?' unless $question =~ /\?$/;
    $answer =~ s/^\s+|\s+$//;
    next unless $answer =~ /\w+/;
    eval {
        $sth->execute($question, $answer);
    };
}

