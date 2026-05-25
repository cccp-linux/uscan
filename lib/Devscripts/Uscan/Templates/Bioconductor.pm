package Devscripts::Uscan::Templates::Bioconductor;

use strict;

sub transform {
    my $watchSource = shift;
    delete $watchSource->{template};
    my $package = delete $watchSource->{package};

    die 'Missing Package field' unless $package;

    $watchSource->{source} ||= "https://bioconductor.org/packages/$package";
    $watchSource->{matchingpattern}
      ||= '.*_@ANY_VERSION@.tar.gz';    # zip and tgz files are binary packages
    $watchSource->{compression}    ||= 'xz';
    $watchSource->{dversionmangle} ||= 's/\+dfsg[0-9]*//g';
    $watchSource->{downloadurlmangle}
      ||= 's%.*/src/contrib/%https://bioconductor.org/packages/release/bioc/src/contrib/%';
    $watchSource->{repacksuffix} ||= '+dfsg';

    return $watchSource;
}

1;
