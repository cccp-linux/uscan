package Devscripts::Utils;

use strict;
use Devscripts::Output;
use Dpkg::IPC;
use Exporter 'import';

our @EXPORT = qw(ds_exec ds_exec_no_fail);

sub ds_exec_no_fail {
    {
        local $, = ' ';
        ds_debug "Execute: @_...";
    }
    spawn(
        exec       => [@_],
        to_file    => '/dev/null',
        wait_child => 1,
        no_check   => 1,
        # XXX: Backwards compatibility, remove after dpkg 1.24.0.
        nocheck => 1,
    );
    return $?;
}

sub ds_exec {
    {
        local $, = ' ';
        ds_debug "Execute: @_...";
    }
    spawn(
        exec       => [@_],
        wait_child => 1,
        no_check   => 1,
        # XXX: Backwards compatibility, remove after dpkg 1.24.0.
        nocheck => 1,
    );
    if ($?) {
        local $, = ' ';
        ds_die "Command failed (@_)";
    }
}

1;
