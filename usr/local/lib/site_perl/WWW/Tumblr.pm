package WWW::Tumblr;

use strict;
use warnings;

require v5.10;

our $VERSION = '5.00_01';

=pod

=head1 NAME

WWW::Tumblr

=head1 SYNOPSIS

  my $t = WWW::Tumblr->new(
     consumer_key    => $consumer_key,
     secret_key      => $secret_key,
     token           => $token,
     token_secret    => $token_secret,
  );
 
  my $blog = $t->blog('perlapi.tumblr.com');
  print Dumper $blog->info;

=head1 MODULE AND TUMBLR API VERSION NOTE

This module supports Tumblr API v2, starting from version 5. Since the previous API was deprecated upstream anyway, there's no backwards compatibility with < 5 versions.

=head1 DESCRIPTION

The new Tumblr API has changed the structure of data to query and its hierarchy. This module now reflects those changes as well. The main three classes are C<<WWW::Tumblr::User>>, C<<WWW::Tumblr::Blog>> and C<<WWW::Tumblr::Tagged>>.You can however, reach them directly C<<WWW::Tumblr>>, in most cases:

  my $t = WWW::Tumblr->new( %set_of_four_tokens );
  my $blog = $t->blog('perlapi.tumblr.com');
 
  if ( my $post = $blog->post( type => 'text', body => 'Hell yeah, son!' ) ) {
     say "I have published post id: " . $post->{id};    
  } else {
     print STDERR Dumper $blog->error;
     die "I couldn't post it :(";
  }

You can also work directly with a C<<WWW::Tumblr::Blog>> class for example:

  my $blog = WWW::Tumblr::Blog->new(
     %four_tokens,
     base_hostname => 'myblogontumblr.com'
  );

All operation methods will return false in case of error and you can check the status with C<<error()>>:

  die Dumper $blog->error unless $blog->info();

On success, methods return whatever Tumblr responded as per API, decoding JSON into Perl using C<<JSON>>. This behavior has not changed from previous versions of this module.

=head1 CAVEATS

=head1 AUTHOR

=head1 SEE ALSO

=head1 COPYRIGHT and LICENSE

=cut

use Moose;
use Carp;
use Data::Dumper;
use HTTP::Request::Common;
use Net::OAuth::Client;
use WWW::Tumblr::API;
use WWW::Tumblr::Blog;
use WWW::Tumblr::User;
use WWW::Tumblr::Authentication;
use LWP::UserAgent;

has 'consumer_key',     is => 'rw', isa => 'Str';
has 'secret_key',       is => 'rw', isa => 'Str';
has 'token',            is => 'rw', isa => 'Str';
has 'token_secret',     is => 'rw', isa => 'Str';

has 'callback',         is => 'rw', isa => 'Str';
has 'error',            is => 'rw', isa => 'WWW::Tumblr::ResponseError';
has 'ua',               is => 'rw', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new };

has 'session_store',	is => 'rw', isa => 'HashRef', default => sub { {} };

has 'oauth',            is => 'rw', isa => 'Net::OAuth::Client', default => sub {
	my $self = shift;
	Net::OAuth::Client->new(
		$self->consumer_key,
		$self->secret_key,
		request_token_path => 'http://www.tumblr.com/oauth/request_token',
		authorize_path => 'http://www.tumblr.com/oauth/authorize',
		access_token_path => 'http://www.tumblr.com/oauth/access_token',
		callback => $self->callback, 
		session => sub { if (@_ > 1) { $self->_session($_[0] => $_[1]) }; return $self->_session($_[0]) },
	);
};

sub user {
    my ( $self ) = shift;
    return WWW::Tumblr::User->new({
        consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        token           => $self->token,
        token_secret    => $self->token_secret,
    });
}

sub blog {
    my ( $self ) = shift;
    my $name = shift or croak "A blog host name is needed.";

    return WWW::Tumblr::Blog->new({
        consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        token           => $self->token,
        token_secret    => $self->token_secret,
        base_hostname   => $name,
    });
}

sub oauth_tools {
	my ( $self ) = shift;
	return WWW::Tumblr::Authentication::OAuth->new(
		consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        callback		=> $self->callback,
	);
}

sub _tumblr_api_request {
    my $self    = shift;
    my $r       = shift; #args

    my $method_to_call = '_' . $r->{auth} . '_request';
    return $self->$method_to_call(
        $r->{http_method}, $r->{url_path}, $r->{extra_args}
    );
}

sub _none_request {
    my $self        = shift;
    my $method      = shift;
    my $url_path    = shift;
    my $params      = shift;

    my $req;
    if ( $method eq 'GET' ) {
        print "Requesting... " .'http://api.tumblr.com/v2/' . $url_path, "\n";
        $req = HTTP::Request->new(
            $method => 'http://api.tumblr.com/v2/' . $url_path,
        );
    } elsif ( $method eq 'POST' ) {
        ...
    } else {
        die "dude, wtf.";
    }

    my $res = $self->ua->request( $req );

    if ( my $prev = $res->previous ) {
        return $prev;
    } else { return $res };
}

sub _apikey_request {
    my $self        = shift;
    my $method      = shift;
    my $url_path    = shift;
    my $params      = shift;

    my $req; # request object
    if ( $method eq 'GET' ) {
        $req = HTTP::Request->new(
            $method => 'http://api.tumblr.com/v2/' . $url_path . '?api_key='.$self->consumer_key.
            ( join '&', map { $_ .'='. $params->{ $_} } keys %$params )
        );
    } elsif ( $method eq 'POST' ) {
        ...
    } else {
        die "$method misunderstood";
    }

    my $res = $self->ua->request( $req );

}

sub _oauth_request {
	my $self = shift;
	my $method = shift;
	my $url_path= shift;
	my $params = shift;

    my $data = delete $params->{data};

	my $request = $self->oauth->_make_request(
		'protected resource', 
		request_method => uc $method,
		request_url => 'http://api.tumblr.com/v2/' . $url_path,
		consumer_key => $self->consumer_key,
	    consumer_secret => $self->secret_key,
		token => $self->token,
		token_secret => $self->token_secret,
		extra_params => $params,
	);
	$request->sign;

    my $authorization_signature = $request->to_authorization_header;

    my $message;
    if ( $method eq 'GET' ) {
        $message = GET 'http://api.tumblr.com/v2/' . $url_path . '?' . $request->normalized_message_parameters, 'Authorization' => $authorization_signature;
    } elsif ( $method eq 'POST' ) {
        $message = POST('http://api.tumblr.com/v2/' . $url_path,
            Content_Type => 'form-data',
            Authorization => $authorization_signature,
            Content => [
                %$params, ( $data ? ( data => $data ) : () )
            ]);
    }

	return $self->ua->request( $message );
}

sub _session {
	my $self = shift;

	if ( ref $_[0] eq 'HASH' ) {
		$self->session_store($_[0]);
	} elsif ( @_ > 1 ) {
		$self->session_store->{$_[0]} = $_[1]
	}
	return $_[0] ? $self->session_store->{$_[0]} : $self->session_store;
}

1;

