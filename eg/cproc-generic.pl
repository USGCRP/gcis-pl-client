#!/usr/bin/env perl

# This creates a generic publication for the references having a reftype = 'Conference Proceedings'.
# The generic publication is subequently associated with the reference.

use v5.14;
use Gcis::Client;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use strict;

$| = 1;
my $url   = "https://data.gcis-dev-front.joss.ucar.edu";
my $max_update = 1;
my $dry_run = 0;
my $help = 0;
my $result = GetOptions ("url=s" => \$url,
                    "max_update=i"   => \$max_update,
                    "dry_run"  => \$dry_run,
                    'help|?' => \$help);

pod2usage(1) if $help;

print " url $url\n";
say " max update : $max_update";
say " dry run" if $dry_run;

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
    next if $_->{attrs}->{reftype} ne "Conference Proceedings";
    next if $_->{child_publication_id};
    $n_update++;
    last if $n_update > $max_update;

    my $generic_pub->{attrs} = {};
    for my $a (qw(Author Title reftype Date DOI URL)) {
        $generic_pub->{attrs}->{$a} = $_->{attrs}->{$a};
    }

    $generic_pub->{attrs}->{'Year of Conference'} = $_->{attrs}->{'Year of Conference'};
    $generic_pub->{attrs}->{'Conference Name'} = $_->{attrs}->{'Conference Name'};
    $generic_pub->{attrs}->{'Conference Location'} = $_->{attrs}->{'Conference Location'};

    say "updating title : $_->{attrs}->{Title}, uri : $_->{uri}";
    
    if ($dry_run) {
        say "would have updated this reference";
        next;
    }

    my $new_pub = $g->post("/generic", $generic_pub) or error $g->error;
    my $ref_form = $g->get("/reference/form/update/$_->{identifier}");
    $ref_form->{child_publication_uri} = $new_pub->{uri};
    $ref_form->{publication_uri} = $g->get($ref_form->{publication_uri})->{uri};
    delete $ref_form->{sub_publication_uris};

    $g->post("/reference/$_->{identifier}", $ref_form) or die $g->error;  
  
}

say "done";

__END__

=head1 NAME

sample - Using Getopt::Long and Pod::Usage

=head1 SYNOPSIS

sample [options] [file ...]

Options:
-help provides a brief help message
-man full documentation

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> creates child publications of class 'generic' for reference types of
class 'Conference Proceedings.'  The program is designed to allow users to select
how many new child pubs to create, and displays the title and UUID pertaining to
each new child pub entry generated.  It is designed to run data-stage.

=cut
