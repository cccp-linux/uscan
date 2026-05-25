package Devscripts::Uscan::Templates::Github;

use strict;

sub transform {
    my $watchSource = shift;
    delete $watchSource->{template};
    my $owner          = delete $watchSource->{owner};
    my $project        = delete $watchSource->{project};
    my $dist           = delete $watchSource->{dist};
    my $custom_version = delete $watchSource->{customversion} || '';
    my $version_regexp = $custom_version || $watchSource->{versiontype};

    die 'Missing Owner/Project or Dist' unless $dist or ($owner and $project);

    if ($dist) {
        $dist =~ s#^.*?github\.com#https://api.github.com/repos#;
        $dist =~ s/\.git$//;
    } else {
        $dist = "https://api.github.com/repos/$owner/$project";
    }

    $watchSource->{source} ||= "$dist/"
      . ($watchSource->{releaseonly} ? 'releases' : 'git/matching-refs/tags/');
    $watchSource->{matchingpattern}
      ||= 'https://api.github.com/repos/[^/]+/[^/]+/'
      . ($watchSource->{releaseonly} ? 'tarball/' : 'git/refs/tags/')
      . '(?>[^/]+(?<=(?:\D|alpha|beta|rc))\-)?'
      . $version_regexp
      . '(?:(?=")|$)';
    $watchSource->{downloadurlmangle}
      ||= 's%(api.github.com/repos/[^/]+/[^/]+)/git/refs/%$1/tarball/refs/%g';
    $watchSource->{filenamemangle} ||= (
        $watchSource->{component}
        ? 's%.*/(?:[^/]+(?<=(?:\D|alpha|beta|rc))\-)?'
          . $version_regexp
          . '%@PACKAGE@-@COMPONENT@-$1.tar.gz%'
        : 's%.*/(?:[^/]+(?<=(?:\D|alpha|beta|rc))\-)?'
          . $version_regexp
          . '%@PACKAGE@-$1.tar.gz%'
    );
    $watchSource->{searchmode} ||= 'plain';
    $watchSource->{pgpmode}    ||= 'none';
    return $watchSource;
}

1;
