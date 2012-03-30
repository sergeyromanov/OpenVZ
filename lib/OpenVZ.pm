package OpenVZ;

# ABSTRACT: Base class for OpenVZ utilities like vzctl

=for stopwords OpenVZ vzctl vzlist STDOUT STDERR hashref params

=head1 SYNOPSIS

  use parent OpenVZ;

  #XXX: need to add more examples

=head1 DESCRIPTION

This is a base class for OpenVZ utilities like vzctl and vzlist.  It shouldn't
be used generally outside of this framework.

=cut

use 5.006;

use strict;
use warnings;

# This way, we don't need to remember to use autoclean in our submodules.
use namespace::autoclean ();
sub import { return namespace::autoclean->import( -cleanee => scalar caller ) }

use Carp;

#use Config::NameValue;
#use Regexp::Common qw( URI net );

use File::Which;
use IPC::Run3::Simple;
use Params::Validate qw( validate ARRAYREF );
use Scalar::Util 'blessed';
use Sub::Exporter;
use Sub::Exporter::Util 'curry_method';
use Sub::Exporter::ForMethods 'method_installer';

my @exports;

# @exports holds the names of functions to be exported.  The easiest way to
# maintain this is to push the name of the function right before it is
# defined.

############################################################################
# Public Functions

=function new

If you prefer an object oriented interface then just C<use OpenVZ::submodule> and
call the new function.  All of the following functions will be available as
methods.

  $vzctl = OpenVZ::vzctl->new;
  $vzctl->set({ ctid => 101, name => 'user101', save => '' });

=function execute

This function should not be called directly unless you know what you're doing.

C<execute> uses L<IPC::Run3::Simple>'s C<run3> function to make system calls.
C<run3> returns whatever is sent to STDOUT, STDERR and the exit value as well
as the execution time of the system call.

This function is the workhorse of this package.  It expects the following
parameters as a hashref

  command => program name to be called (e.g., vzctl) (STRING)
  params  => parameters to be passed to the command to be called (ARRAYREF)

C<params> is optional.

The params value will not be checked for validity.  It is assumed that if you
are calling this subroutine you have already validated whatever is going to be
passed on the command line.

=cut

{  # Quick! Hide!!

    ## no critic qw( Bangs::ProhibitVagueNames Subroutines::RequireArgUnpacking )
    my $object;
    sub new { return bless \$object, ref $_[0] || $_[0] }
    ## use critic

    my %program;

    # Determines if the specified command is installed, what its path is and
    # caches it. Used in execute.

    my $find_command = sub {

        shift if blessed $_[0] or $_[0] eq __PACKAGE__;

        #my ( $pgm, $params ) = @_;
        my $pgm = shift;

        return 1
            if exists $program{ path }{ $pgm };

        $program{ path }{ $pgm } = which( $pgm )
            or croak "Could not find $pgm in path ($ENV{PATH})"; ## no critic qw( ErrorHandling::RequireUseOfExceptions )

        return 1;

    };

    push @exports, 'execute';

    sub execute { ## no critic qw( Subroutines::RequireArgUnpacking )

        shift if blessed $_[0] or $_[0] eq __PACKAGE__;

        my %arg = validate(
            @_, {
                'command' => { callbacks => { 'find command path' => $find_command } },
                'params' => { type => ARRAYREF, optional => 1 },
            } );

        # XXX: Need to handle also the case of a hashref
        return run3( [ $program{ path }{ $arg{ command } }, @{ $arg{ params } } ] );

    }

} ## end hiding

############################################################################
# Utility Functions - not for general consumption

############################################################################
# Setup exporter

my %exports = map { ( $_ => curry_method ) } @exports;

my $config = {

    exports   => \%exports,
    installer => method_installer,

};

Sub::Exporter::setup_exporter( $config );

1;
