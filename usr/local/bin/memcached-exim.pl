#!/usr/bin/perl

# http://wiki.exim.org/GreylistMemcachedPerl

use Cache::Memcached;
use strict;

my $memd = _create_memcached();

sub check_greylist {
  my $key = &_tuple(@_);
  my $now = time();
  my $timeout = ( $_[4] || 5 ) * 60;      # Minutes to seconds, default 5
  my $expire = ( $_[5] || 10 ) *24*60*60;  # Days to seconds, default 7 (=> 10)
  my $val = $memd->get($key);
  if ( $val ) {
    # Update expiration
    $memd->replace($key, $val, $now + $expire);
    # Has exceeded the timeout, don't defer it
    if ( $now > $val + $timeout ) {
      Exim::log_write("PASS GREYLIST: '$key'");
      return(0);
    }
    #Exim::log_write("CONTINUE GREYLIST: '$key' still greylisted for " . ($val + $timeout - $now) . " seconds");
    return(1);
  }
  else {
    $memd->set($key, $now ,$now + $expire);
    #Exim::log_write("SET GREYLIST: '$key'");
    return(1);
  }
}

sub greylist_time {
  my $key = &_tuple(@_);
  my $now = time();
  my $timeout = ( $_[4] || 5 ) * 60;      # Minutes to seconds, default 5
  if ( my $val = $memd->get($key) ) {
    my $left = $val + $timeout - $now;
    $left = sprintf("%0i:%02i", int($left/60), $left % 60);
    return( $left);
  }
  # Should never get here if because this sub should never
  # have been called if there is no greylist record, but 
  # handle it by just printing default
  return( sprintf("%0i:%02i", int($timeout/60), $timeout % 60));
}

sub _tuple {
  my ($ip,$from,$local_part,$domain) = @_;
  return( $ip . ":" . $from . ":" . $local_part . '@' . $domain );
}

sub _create_memcached {
  my $config = "/etc/exim4/memcached.conf";
  my $namespace = 'exim:';  # set default namespace
  my $servers;
  if ( -f $config ) {
    open(my $fh, "<", $config);
    while(<$fh>) {
      chomp($_);
      if ( my ($arg,$val) = split(/=/,$_) ) {
        next if ( $arg =~ /#/ );
        $arg =~ s/\s+//;
        $val =~ s/\s+//;
        if ( $arg =~ /\bserver\b/ ) {
          next if ( $val !~ /^[-\w\d\.]+:\d+$/ );
          push( @$servers, $val );
        }
        elsif ( $arg =~ /\bnamespace\b/ ) {
          next if ( $val !~ /^[-\w\d\.]+$/ );
          $namespace = $val . ":";
        }
      }
    }
    close $fh;
  }
  $servers ||= [ 'localhost:11211' ];  # Set a default if nothing specified
  my $m = Cache::Memcached->new( {
      'servers'            => $servers,
      'namespace'          => $namespace,
      'debug'              => 0,
      'compress_threshold' => 10_000
    } );
  return($m);
}
