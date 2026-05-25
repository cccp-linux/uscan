package Devscripts::Uscan::Templates::Pypi;

use strict;

sub transform {
    my $watchSource = shift;
    delete $watchSource->{template};
    my $dist = delete $watchSource->{dist};

    die 'Missing Dist' unless $dist;

    $watchSource->{source}          ||= "https://pypi.debian.net/$dist/";
    $watchSource->{matchingpattern} ||= "$dist" . '-@ANY_VERSION@.tar.gz';
    $watchSource->{searchmode}      ||= 'plain';
    $watchSource->{pgpmode}         ||= 'none';

    $watchSource->{uversionmangle} = 's/(rc|a|b|c)/~$1/'
      unless defined $watchSource->{uversionmangle};

    return $watchSource;
}

1;
