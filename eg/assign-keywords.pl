#!/usr/bin/env perl

use lib '../lib';
use Tuba::Client;
use Data::Dumper;
use v5.14;

my $c = Tuba::Client->new->find_credentials->login;

my $finding = 'more-needed-to-reduce-us-emission';

my $existing = $c->get(qq[/report/nca3draft/chapter/our-changing-climate/finding/$finding]);

#say Dumper($existing->{gcmd_keywords});
#say Dumper($existing->{keywords});

my $this =
           {
             'id' => '5286',
             'category' => 'EARTH SCIENCE',
             'topic' => 'HUMAN DIMENSIONS',
             'term' => 'ENVIRONMENTAL IMPACTS',
             'level1' => 'FOSSIL FUEL BURNING',
             'level2' => undef,
             'level3' => undef,
           };
my $i = 1;
for my $this (@{ $existing->{keywords} }) { 
    $this->{_delete_extra} = 1 if $i==1;
    say $i++;
    my $got = $c->post("/report/nca3draft/chapter/our-changing-climate/finding/keywords/$finding",
        $this
    );
    say Dumper($this);
    say Dumper($got);
}

