#!/usr/bin/perl

use strict;
use warnings;
use LWP;

my $url = shift || "http://sgjlab.org/ralee-version.html";
my $ua = new LWP::UserAgent;
$ua->env_proxy;
$ua->timeout(10);

my $req = new HTTP::Request GET => $url;
my $res = $ua->request( $req );
if( $res->is_success ) {
    $_ = $res->content;
    if( my ($v) = /VERSION ([\d\.]+)/i ) {
	print "$v";
    }
}
else {
    print "-1";
}
