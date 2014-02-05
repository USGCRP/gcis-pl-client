package Tuba::Client;
use Mojo::UserAgent;
use Mojo::Base -base;
use Mojo::Log;
use JSON::XS;
use Path::Class qw/file/;
use Data::Dumper;
use v5.14;

has url      => 'http://localhost:3000';
has 'key';
has 'error';
has ua       => sub { state $ua   ||= Mojo::UserAgent->new(); };
has logger   => sub { state $log  ||= Mojo::Log->new(); };
has json     => sub { state $json ||= JSON::XS->new(); };
sub auth_hdr { ($a = shift->key )  ? ("Authorization" => "Basic $a") : () };
sub hdrs     { +{shift->auth_hdr,      "Accept"        => "application/json" } };

sub _follow_redirects {
    my $s = shift;
    my $tx = shift;
    while ($tx && $tx->res && $tx->res->code && $tx->res->code == 302) {
        my $next = $tx->res->headers->location;
        $tx = $s->ua->get($next => $s->hdrs);
    }
    return $tx;
}

sub get {
    my $s = shift;
    my $path = shift;
    my $tx = $s->ua->get($s->url."$path" => $s->hdrs);
    $tx = $s->_follow_redirects($tx);
    my $res = $tx->success;
    unless ($res) {
        if ($tx->res->code && $tx->res->code == 404) {
            # $s->logger->debug("not found : $path");
            $s->error("not found : $path");
            return;
        }
        $s->error($tx->error);
        $s->logger->error($tx->error);
        return;
    };
    my $json = $res->json or do {
        $s->logger->debug("no json from $path : ".$res->to_string);
        $s->error("No JSON returned from $path : ".$res->to_string);
        return;
    };
    return wantarray && ref($json) eq 'ARRAY' ? @$json : $json;
}

sub post {
    my $s = shift;
    my $path = shift;
    my $data = shift;
    my $tx = $s->ua->post($s->url."$path" => $s->hdrs => json => $data );
    $tx = $s->_follow_redirects($tx);
    my $res = $tx->success or do {
        $s->logger->error("$path : ".$tx->error.$tx->res->body);
        return;
    };
    return unless $res;
    my $json = $res->json or return $res->body;
    return $res->json;
}

sub delete {
    my $s = shift;
    my $path = shift;
    my $tx = $s->ua->delete($s->url."$path" => $s->hdrs);
    my $res = $tx->success;
    unless ($res) {
        if ($tx->res->code && $tx->res->code == 404) {
            $s->error("not found : $path");
            return;
        }
        $s->error($tx->error);
        $s->logger->error($tx->error);
        return;
    };
    return $res->body;
}

sub put_file {
    my $s = shift;
    my $path = shift;
    my $file = shift;
    my $data = file($file)->slurp;
    my $tx = $s->ua->put($s->url."$path" => $s->hdrs => $data );
    $tx = $s->_follow_redirects($tx);
    my $res = $tx->success or do {
        $s->logger->error("$path : ".$tx->error.$tx->res->body);
        return;
    };
    return unless $res;
    my $json = $res->json or return $res->body;
    return $res->json;
}


sub post_quiet {
    my $s = shift;
    my $path = shift;
    my $data = shift;
    my $tx = $s->ua->post($s->url."$path" => $s->hdrs => json => $data );
    $tx = $s->_follow_redirects($tx);
    my $res = $tx->success or do {
        $s->logger->error("$path : ".$tx->error.$tx->res->body) unless $tx->res->code == 404;
        return;
    };
    return unless $res;
    my $json = $res->json or return $res->body;
    return $res->json;
}

sub find_credentials {
    my $s = shift;
    my $home = $ENV{HOME};
    my ($json_file) = grep {
      my ($which) = ( $_ =~ /(?:^|\/)\.gcis\.?(.*)\.json$/ );
      die "bad name : $_" unless $which;
      $s->url =~ /$which/;
    } glob "$home/.gcis.*.json";
    unless ($json_file) {
        $s->logger->warn("no credentials found for ".$s->url);
        return;
    }
    $s->logger->debug("Credentials from $json_file will be used for ".$s->url);
    my $key = $s->json->decode(scalar file($json_file)->slurp)->{key};
    $s->key($key);
    return $s;
}

sub login {
    my $c = shift;
    my $got = $c->get('/login') or return;
    $c->get('/login')->{login} eq 'ok' or return;
    return $c;
}

sub get_chapter_map {
    my $c = shift;
    my $report = shift or die "no report";
    my $all = $c->get("/report/$report/chapter?all=1") or die $c->url.' : '.$c->error;
    my %map = map { $_->{number} // $_->{identifier} => $_->{identifier} } @$all;
    return wantarray ? %map : \%map;
}

sub figures {
    my $c = shift;
    my %a = @_;
    my $report = $a{report} or die "no report";
    if (my $chapter_number = $a{chapter_number}) {
        $c->{_chapter_map}->{$report} //= $c->get_chapter_map($report);
        $a{chapter} = $c->{_chapter_map}->{$report}->{$chapter_number};
    }
    my $figures;
    if (my $chapter = $a{chapter}) {
        $figures = $c->get("/report/$report/chapter/$chapter/figure?all=1") or die $c->error;
    } else {
        $figures = $c->get("/report/$report/figure?all=1") or die $c->error;
    }
    return wantarray ? @$figures : $figures;
}

sub get_form {
    my $c = shift;
    my $obj = shift;
    my $uri = $obj->{uri} or die "no uri in ".Dumper($obj);
    # The last backslash becomes /form/update
    $uri =~ s[/([^/]+)$][/form/update/$1];
    return $c->get($uri);
}

sub connect {
    my $class = shift;
    my %args = @_;

    my $url = $args{url} or die "missing url";
    my $c = $class->new;
    $c->url($url);
    $c->find_credentials->login or die "Failed to log in to $url";
    return $c;
}

1;

__END__

=head1 NAME

Tuba::Client -- Perl client for interacting with the GCIS API

=head1 SYNOPSIS

    my $c = Tuba::Client->new->find_credentials->login;

    my $c = Tuba::Client->new;
    $c->url("http://data.globalchange.gov");
    $c->logger(Mojo::Log->new(path => 'tuba.log');

    my $c = Tuba::Client->new(url => 'http://data.globalchange.gov');

    my $c = Tuba::Client->new
        ->url('http://data.globalchange.gov')
        ->logger($logger)
        ->find_credentials
        ->login;

    my $chapters = $c->get("/report/nca3draft/chapter?all=1") or die $c->error;

    my $ref = $c->post(
      "/reference",
      {
        identifier        => $uuid,
        publication_uri  => "/report/$parent_report",
        sub_publication_uris => $chapter_uris,
        attrs             => $rec,
      }
    ) or die $c->error;

=head1 DESCRIPTION

This is a simple client for Tuba, based on L<Mojo::UserAgent>.

=head1 METHODS

=head2 connect

    my $c = Tuba::Client->connect(url => $url);

Shorthand for Tuba::Client->new->url($url)->find_credentials->login or die "Failed to log in to $url";

=head2 find_credentials

Looks for a file like the one that can be downloaded from L<http://data.globalchange.gov/login_key.json>.

This file should be saved in a file named $HOME/.gcis.json, or $HOME/.gcis.<foo>.json, where
<foo> is a substring of the URL.  (e.g. .gcis.local.json for http://localhost:3000)

    $c->find_credentials;

=head2 login

Verify that a get request to /login succeeds.

Returns the client object if and only if it succeeds.

    $c->login;

=head2 get_chapter_map

Get a map from chapter number to identifer.

    my $identifier = $c->-get_chapter_map->{1}

=head2 get

    Get a URL, requesting JSON, converting an arrayref to an array
if called in an array context.

=head1 SEE ALSO

L<Mojo::UserAgent>, L<Mojo::Log>

=cut
