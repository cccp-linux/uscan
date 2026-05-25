package Devscripts::Uscan::Modes::Git;

use strict;
use Cwd qw/abs_path cwd/;
use Devscripts::Uscan::Output;
use Devscripts::Uscan::Utils;
use Devscripts::Uscan::Modes::_vcs;
use Dpkg::IPC;
use File::Path 'remove_tree';
use Moo::Role;

sub git_search {
    my ($self) = @_;
    my ($newfile, $newversion, $mangled_newversion);

    $newfile = $self->parse_result->{filepattern};

    # Try to use local upstream branch if available
    if (-d '.git') {
        my $out;
        spawn(
            exec       => ['git', 'remote', '--verbose', 'show'],
            wait_child => 1,
            to_string  => \$out
        );
        uscan_debug "'git remote --verbose show' output:\n"
          . "========\n"
          . $out
          . "========\n";

        # Check whether any remote repository URLs match debian/watch Source
        if ($out and $out =~ /^(\S+)\s+\Q$self->{parse_result}->{base}\E/m) {
            my $remote = $1;
            $self->downloader->git_upstream($remote);
            uscan_verbose join ' ',
              "'$self->{parse_result}->{base}' matches debian/watch;",
              "using remote '$remote'";

            # Run `git fetch` to update the repository
            my @args = ('fetch');
            push(@args, '--recurse-submodules') if $self->git->{modules};
            uscan_debug join(' ', 'git', @args, $remote);
            spawn(
                exec       => ['git', @args, $remote],
                wait_child => 1
            );

            $newfile = "$remote/HEAD" if $self->versionless;
        }
    }

    my @args   = ();
    my $curdir = cwd();

    # Clone git repository (HEAD or heads/<branch> only)
    if ($self->versionless and not $self->downloader->git_upstream) {
        push(@args, '--quiet') if not $verbose;
        push(@args, '--bare')  if not $self->git->{modules};

        if ($self->gitpretty eq 'describe') {
            $self->git->{mode} = 'full';
        }

        if ($self->git->{mode} eq 'shallow') {
            push(@args, '--depth=1');
            $self->downloader->gitrepo_state(1);
        } else {
            $self->downloader->gitrepo_state(2);
        }

        if ($newfile ne 'HEAD') {
            $newfile =~ s&^heads/&&;    # Set to <branch>
            push(@args, '-b', "$newfile");
        }

        # Clone main repository
        uscan_exec(
            'git', 'clone', @args,
            $self->parse_result->{base},
            "$self->{downloader}->{destdir}/" . $self->gitrepo_dir
        );

        chdir "$self->{downloader}->{destdir}/$self->{gitrepo_dir}";
    }

    # Generate filename for pristine tarball
    if ($self->versionless) {
        my @git = ('git');
        push(@git, '--git-dir=.')
          if not $self->git->{modules} and not $self->downloader->git_upstream;

        if ($self->gitpretty eq 'describe') {
            # git describe
            # use unannotated tags to be on safe side
            @args = qw/describe --tags/;
            push(@args, $newfile);

            uscan_debug join(' ', @git, @args);

            spawn(
                exec       => [@git, @args],
                wait_child => 1,
                to_string  => \$newversion
            );
            $newversion =~ s/-/./g;
            chomp($newversion);
            $mangled_newversion = $newversion;

            if (
                mangle(
                    $self->watchfile,            'uversionmangle:',
                    \@{ $self->uversionmangle }, \$mangled_newversion
                )
            ) {
                return undef;
            }
        } else {
            # git log
            my $tmp = $ENV{TZ};
            $ENV{TZ} = 'UTC';
            @args = qw/log -1/;
            push(@args, "--date=format-local:$self->{gitdate}");
            push(@args, "--no-show-signature");
            push(@args, "--pretty=$self->{gitpretty}");
            push(@args, $newfile);

            uscan_debug join(' ', @git, @args);

            spawn(
                exec       => [@git, @args],
                wait_child => 1,
                to_string  => \$newversion
            );
            $ENV{TZ} = $tmp;
            chomp($newversion);
            $mangled_newversion = $newversion;
        }
        chdir "$curdir";
    } else {    # not $self->versionless
        @args
          = $self->downloader->git_upstream
          ? ('show-ref', '--tags')
          : ('ls-remote', '--tags', $self->parse_result->{base});
        # Generate filename for pristine tarball using git tags
        ($mangled_newversion, $newversion, $newfile)
          = get_refs($self, ['git', @args], qr/^\S+\s+([^\^\{\}]+)$/, 'git');
        return undef if !defined $newversion;
    }
    return ($mangled_newversion, $newversion, $newfile);
}

sub git_upstream_url {
    my ($self) = @_;
    my $upstream_url
      = $self->parse_result->{base} . ' ' . $self->search_result->{newfile};
    return $upstream_url;
}

*git_newfile_base = \&Devscripts::Uscan::Modes::_vcs::_vcs_newfile_base;

sub git_clean {
    my ($self) = @_;

    # If git cloned repo exists and not --debug ($verbose=2) -> remove it
    if (    $self->downloader->gitrepo_state > 0
        and $verbose < 2
        and !$self->downloader->git_upstream) {
        my $err;
        uscan_verbose "Removing git repo ($self->{downloader}->{destdir}/"
          . $self->gitrepo_dir . ")";
        remove_tree "$self->{downloader}->{destdir}/" . $self->gitrepo_dir,
          { error => \$err };
        if (@$err) {
            local $, = "\n\t";
            uscan_warn "Errors during git repo clean:\n\t@$err";
        }
        $self->downloader->gitrepo_state(0);
    } else {
        uscan_debug "Keep git repo ($self->{downloader}->{destdir}/"
          . $self->gitrepo_dir . ")";
    }
    return 0;
}

1;
