#!/usr/bin/perl -w

package birdctl;

use strict;
use warnings;

use Carp;
use Params::Validate qw(:all);
use IO::Socket::UNIX;

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
  /^0001 BIRD 1\.[\d\.]+ ready\.$/ or croak "Bad 'hello' received";

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
sub cmd {
  my $self = shift(@_);
  my @result = $self->long_cmd(@_);
  return pop(@result);
};

1;
