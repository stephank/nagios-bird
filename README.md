# Nagios BIRD plugins

This repository contains [Nagios] plugins for monitoring the
[BIRD routing daemon]. The plugins are written in Perl.

## bird.ctl

This is a simple Perl module for talking to BIRD's control socket. Briefly,
you may use it as follows:

    use birdctl;
    my $bird = new birdctl(
      socket => $socket_path,
      restrict => 1,
    );
    my $final_result_line = $bird->cmd("show route count");
    my @result_lines = $bird->long_cmd("show route protocol kernel");

The return values of `cmd` and `long_cmd` are the lines verbatim as received
from BIRD, including status codes.

## check_proto_bird

This plugin monitors a protocol in the BIRD configuration.

    Usage: %s -p <protocol> [ -r <table> -z -s <socket> ]

 * BIRD must be running, or CRITICAL is reported.
 * The protocol must be up, or CRITICAL is reported.
 * Optionally, routes must be imported, or CRITICAL is reported.
 * Otherwise, report OK and display the number of routes imported.

The plugin looks for routes in the default table (called `master`), or in the
table specified with option `-r`. If the option `-z` is specified, the plugin
will also report CRITICAL if no routes were found.

If the BIRD control socket is not in the default location `/var/run/bird.ctl`,
then an alternate location can be specified with option `-s`.

Option `-p` is required, and specifies the protocol name to look for.

 [Nagios]: http://www.nagios.org/
 [BIRD routing daemon]: http://bird.network.cz/
