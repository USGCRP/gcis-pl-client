#!/usr/bin/env perl

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Gcis::Client;
use Test::More qw/no_plan/;
use v5.14;
no warnings 'uninitialized';

sub usage { die "Usage : $0 <doi> [<url>]\n"; }

my $doi = shift @ARGV or usage();
my $url = shift @ARGV || "http://localhost:3000";

my $c = Gcis::Client->new->url($url);
my $d = Gcis::Client->new->accept("application/vnd.citationstyles.csl+json;q=0.5")
                          ->url("http://dx.doi.org");

my $gcis = $c->get("/article/$doi") or die "Article $doi not found in gcis.";
$gcis->{journal} = $c->get("/journal/$gcis->{journal_identifier}");
my $crossref = $d->get("/$doi");

print Dumper($gcis);
print Dumper($crossref);

is $gcis->{title},          $crossref->{title},  "title";
is $gcis->{journal_vol},    $crossref->{volume}, "volume";
is $gcis->{year},           $crossref->{issued}{'date-parts'}[0][0], "year";
is $gcis->{journal}{title}, $crossref->{'container-title'}, "journal title";

