package Devscripts::Uscan::Templates::Gitlab;

use strict;

sub transform {
    my $watchSource = shift;
    delete $watchSource->{template};
    my $url            = delete $watchSource->{dist};
    my $custom_version = delete $watchSource->{customversion} || '';
    my $version_regexp = $custom_version || $watchSource->{versiontype};

    die 'Missing dist'   unless $url;
    die "Bad dist: $url" unless $url =~ m#^https?://#;

    $url =~ s#/+$##;
    $watchSource->{source}          ||= $url;
    $watchSource->{matchingpattern} ||= ".*?$version_regexp";
    $watchSource->{filenamemangle}  ||= (
        $watchSource->{component}
        ? "s%.*?$version_regexp\$%\@PACKAGE\@-\@COMPONENT\@-\$1.tar.gz%"
        : "s%.*?$version_regexp\$%\@PACKAGE\@-\$1.tar.gz%"
    );
    $watchSource->{uversionmangle} ||= 'auto';
    $watchSource->{pgpmode}        ||= 'none';
    $watchSource->{mode}           ||= 'gitlab';
    return $watchSource;
}

1;
