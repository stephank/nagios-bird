#!/usr/bin/perl -w

use strict;
use warnings;

use Nagios::Plugin;
use birdctl;

my $np = Nagios::Plugin->new(
  plugin => "check_bird_proto", shortname => "BIRD_PROTO", version => "0.1",
  usage => "Usage: %s -p <protocol> [ -r <table> -z -s <socket> ]",
);
$np->add_arg(
  spec => "protocol|p=s",
  help => "The name of the protocol to monitor.",
  required => 1,
);
$np->add_arg(
  spec => "table|r=s",
  help => "The table to search for routes.",
  default => "master",
);
$np->add_arg(
  spec => "zero|z",
  help => "Whether zero routes is an error.",
);
$np->add_arg(
  spec => "socket|s=s",
  help => "The location of the BIRD control socket.",
  default => "/var/run/bird.ctl",
);
$np->getopts;

# Handle timeouts (also triggers on invalid command)
$SIG{ALRM} = sub { $np->nagios_exit(CRITICAL, "Timeout (possibly invalid command)") };
alarm $np->opts->timeout;

eval q{
  my $bird = new birdctl(socket => $np->opts->socket, restrict => 1);

  # Get protocol information
  my @status;
  foreach ($bird->long_cmd("show protocols " . $np->opts->protocol)) {
    # Find the first 1002 line.
    /^1002-/ and @status = split(/\s+/, substr($_, 5)) and last;
    # Fall through: no information found, print closing line.
    /^\d{4} / and $np->nagios_exit(CRITICAL, $_);
  }

  # Check status
  if ($status[3] ne "up") {
    if ($status[5]) {
      $np->nagios_exit(CRITICAL, "Protocol $status[0] is $status[3] - info: $status[5]");
    }
    else {
      $np->nagios_exit(CRITICAL, "Protocol $status[0] is $status[3] - info: Protocol Down");
    }
  }

  # Inspect routes imported from this protocol
  $_ = $bird->cmd("show route table " . $np->opts->table . " protocol " . $np->opts->protocol . " count");
  /^0014 (\d+) of \d+ routes for \d+ networks$/ or $np->nagios_exit(CRITICAL, $_);

  # Final status
  $np->nagios_exit(
    $np->opts->zero && $1 eq "0" ? CRITICAL : OK,
    "Protocol $status[0] is $status[3] - $1 routes imported."
  );
};
if ($@) { $np->nagios_exit(CRITICAL, $@); }
