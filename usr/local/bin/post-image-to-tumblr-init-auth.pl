#!/usr/bin/perl
# grabbed at http://ryanwark.com/blog/posting-to-the-tumblr-v2-api-in-perl

use LWP::UserAgent;
use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
use HTTP::Request::Common;
my $ua = LWP::UserAgent->new;

use Getopt::Long;
## get tty input with standard opts.
my $getopt;
my $consumer_key;
my $consumer_secret;
eval {
	$getopt = GetOptions("key=s" => \$consumer_key,
			     "secret=s" => \$consumer_secret);
};
die "Set consumer key with --key arg! Exiting" unless $consumer_key;
die "Set consumer secret with --secret arg! Exiting" unless $consumer_secret;
wd
my $request_url = 'http://www.tumblr.com/oauth/request_token';
my $access_url = 'http://www.tumblr.com/oauth/access_token';
my $authorize_url = 'http://www.tumblr.com/oauth/authorize';
####
my $request =
        Net::OAuth->request('consumer')->new(
          consumer_key => $consumer_key,
          consumer_secret => $consumer_secret,
          request_url => $request_url,
          request_method => 'POST',
          signature_method => 'HMAC-SHA1',
          timestamp => time,
          nonce => nonce(),
        );

$request->sign;

print $request->to_url."\n";
my $res = $ua->request(POST $request->to_url);
my $token;
my $token_secret;
if ($res->is_success) {
  my $response = Net::OAuth->response('request token')->from_post_body($res->content);
  $token=$response->token;
  $token_secret=$response->token_secret;
  print "Got Request Token ", $token, "\n";
  print "Got Request Token Secret ", $token_secret, "\n";
  print "Go to $authorize_url?oauth_token=".$token."\n";
} else {
  die "Something went wrong";
}

print "Go to the above URL, authorize and give me the oauth_verifier token. Then press <ENTER>\n";
my $verifier = <STDIN>;
chomp $verifier;

$request =
        Net::OAuth->request('access token')->new(
          consumer_key => $consumer_key,
          consumer_secret => $consumer_secret,
          token => $token,
          token_secret => $token_secret,
          request_url => $access_url,
          request_method => 'POST',
          signature_method => 'HMAC-SHA1',
          timestamp => time,
          nonce => nonce(),
          verifier => $verifier,
        );

$request->sign;

#print $request->to_url."\n";

$res = $ua->request(POST $request->to_url);
if ($res->is_success) {
  my $response = Net::OAuth->response('access token')->from_post_body($res->content);
  print "Got Access Token ", $response->token, "\n";
  print "Got Access Token Secret ", $response->token_secret, "\n";
} else {
  die "Something went wrong";
}

sub nonce {
  my @a = ('A'..'Z', 'a'..'z', 0..9);
  my $nonce = '';
  for(0..31) {
    $nonce .= $a[rand(scalar(@a))];
  }

  $nonce;
}
