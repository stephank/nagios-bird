#!/usr/bin/perl -w

package birdctl;

use strict;
use warnings;

use Carp;
use Params::Validate qw(:all);
use IO::Socket::UNIX;
my $birdversion;

# Constructor.
sub new {
  my $class = shift(@_);
  local ($!, $_);

  my %attr = validate(@_, {
    socket => { default => "/var/run/bird.ctl" },
    restrict => 0,
  });

  my $socket = new IO::Socket::UNIX->new(
    Type => SOCK_STREAM,
    Peer => $attr{socket},
  ) or croak "Connection failed: $!";

  defined($_ = <$socket>) or croak "While reading 'hello': $!";

  /^0001 BIRD ([1-2])\.[\d\.]+ ready\.$/ or croak "Bad 'hello' received";
  if ($1 eq "1") {
	$birdversion = 1;
  } elsif ($1 eq "2") {
	$birdversion = 2;
  }
  my $self = {
    _socket => $socket,
  };
  bless $self, $class;

  if ($attr{restrict}) {
    $self->cmd("restrict") =~ /^0016/ or croak "Could not enter restricted mode";
  }

  return $self;
};

# Return an array of lines received in response to the given command.
sub long_cmd {
  my $self = shift(@_);
  my $socket = $self->{_socket};
  local ($!, $_);

  $socket->send(shift(@_) . "\n");

  my @result;
  while (<$socket>) {
    # FIXME: Handle continuations (Rare, I believe)
    push @result, $_;
    /^\d{4} / and return @result;
  }

  # Fall through: no closing line found.
  croak "While reading output: $!";
};

# Return just the finishing line received in response to the given command.
# the last line is "0000" as in bird2 we trash the line and pop the next.
# Also checking if the line is a succesful code starting with 0x
sub cmd {
  my $self = shift(@_);
  my @result = $self->long_cmd(@_);
  my $lastline;
  if ( @result eq 1 ) {
	$lastline = pop(@result);
	if ( $lastline  =~ /^0./ ) {
		return $lastline;
	} else {
		croak "Command not successful ($lastline)";
	}
  } else {
	$lastline = pop(@result);
	if ( $lastline  =~ /^0./ ) {
		return pop(@result);
	} else {
		croak "Command not successful ($lastline)";
	}
  }
};

1;
