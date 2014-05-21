#!/usr/bin/env perl

use v5.14;

use Gcis::Client;

my $c = Gcis::Client->connect(url => $ARGV[0]);

goto CHAPTER;
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
) or die $c->error;

CHAPTER:
say "adding";
# Add a chapter
$c->post(
    "/report/my-new-report/chapter",
    {
        report_identifier => "my-report",
        identifier        => "my-chapter-identifier",
        title             => "Some Title",
        number            => 12,
        sort_key          => 100,
        # optional DOI
    }
) or die $c->error;

