#!/usr/bin/env perl

use v5.14;

use Gcis::Client;

my $c = Gcis::Client->connect(url => $ARGV[0]);

$c->post(
  '/report',
  {
    identifier       => 'my-new-report',
    title            => "awesome report",
    frequency        => "1 year",
    summary          => "this is a great report",
    report_type_identifier => "report",
    publication_year => '2000',
    url              => "http://example.com/report.pdf",
  }
);

