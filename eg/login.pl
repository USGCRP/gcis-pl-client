#!/usr/bin/env perl

use v5.14;

use Tuba::Client;
use Data::Dumper;
use Encode;

my $c = Tuba::Client->connect(url => $ARGV[0]);

my $ok  = $c->get("/login");

say Dumper($ok);


