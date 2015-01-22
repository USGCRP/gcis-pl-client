#!/usr/bin/env perl

# This creates a generic publication for the references having a reftype = 'Conference Proceedings'.
# The generic publication is subequently associated with the reference.
# Lines producing output logs are commented out.

use v5.14;
use Gcis::Client;
use Data::Dumper;
use strict;

my $dry_run = 0;
my $max_update = 100;

$| = 1;

say " dry run" if $dry_run;

# my $url = "http://data-stage.globalchange.gov";
my $url = "https://data.gcis-dev-front.joss.ucar.edu";

print " url $url\n";

my $all = "?all=1`";
# my $all = "";
my $ref_search = "/reference.json$all";

my $search = $url.$ref_search;
say " search : $search";

my $g = $dry_run ? Gcis::Client->new(    url => $url)
                 : Gcis::Client->connect(url => $url);
my $refs = $g->get($ref_search);

my $n = @$refs;
say " n refs : $n";
my $n_update = 0;
for (@$refs) { 
 #  say " reftype : $_->{attrs}->{reftype}";
    next if $_->{attrs}->{reftype} ne "Conference Proceedings";
    next if $_->{child_publication_id};
    $n_update++;
    last if $n_update > $max_update;

  # say " uri : $_->{uri}";
  # say " ref :\n".Dumper($_);
    my $generic_pub->{attrs} = {};
    for my $a (qw(Author Title reftype)) {
        $generic_pub->{attrs}->{$a} = $_->{attrs}->{$a};
    }
    $generic_pub->{attrs}->{Year} = $_->{attrs}->{'Year of Conference'};
    $generic_pub->{attrs}->{Publisher} = $_->{attrs}->{'Conference Name'};
    $generic_pub->{attrs}->{Conference_Location} = $_->{attrs}->{'Conference Location'};
    $generic_pub->{attrs}->{Date} = $_->{attrs}->{'Date'};
    $generic_pub->{attrs}->{DOI} = $_->{attrs}->{'DOI'};
    $generic_pub->{attrs}->{URL} = $_->{attrs}->{'URL'};

 #  say " generic_pub :\n".Dumper($generic_pub);
    if ($dry_run) {
        say "updating title : $->{title}, uri : $->{uri}";
        say "would have updated this reference";
        next;
    }
 #   say "updating this reference";
     my $new_pub = $g->post("/generic", $generic_pub) or error $g->error;
 #   say " new uri : $new_pub->{uri}";
 #   say " new pub :\n".Dumper($new_pub);
 
    my $ref_form = $g->get("/reference/form/update/$_->{identifier}");
    $ref_form->{child_publication_uri} = $new_pub->{uri};
    $ref_form->{publication_uri} = $g->get($ref_form->{publication_uri})->{uri};
    delete $ref_form->{sub_publication_uris};

    $g->post("/reference/$_->{identifier}", $ref_form) or die $g->error;  
  
}

say "done";
