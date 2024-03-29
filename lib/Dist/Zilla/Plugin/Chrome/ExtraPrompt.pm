use strict;
use warnings;
package Dist::Zilla::Plugin::Chrome::ExtraPrompt;
{
  $Dist::Zilla::Plugin::Chrome::ExtraPrompt::VERSION = '0.006';
}
# git description: v0.005-1-g6e3387f

BEGIN {
  $Dist::Zilla::Plugin::Chrome::ExtraPrompt::AUTHORITY = 'cpan:ETHER';
}
# ABSTRACT: Perform arbitrary commands when Dist::Zilla prompts you
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with 'Dist::Zilla::Role::Plugin';
use namespace::autoclean;

# since the plugin is never actually instantiated, these attributes
# are mostly useless, but it does serve as a bit of self-documentation...
# and who knows, config.ini-oriented plugins may actually become more
# supported some day.
has command => (
    is => 'ro', isa => 'Str',
    required => 1,
);
has repeat_prompt => (
    is => 'ro', isa => 'Bool',
    default => 0,
);

around register_component => sub
{
    my $orig = shift;
    my $self = shift;
    my ($class, $payload, $section) = @_;

    my $chrome = $section->sequence->assembler->chrome;

    # if this plugin were in dist.ini, it would be applied for everyone, not just you
    $chrome->logger->log_fatal('must be used in ~/.dzil/config.ini -- NOT dist.ini!')
        if $section->sequence->assembler->can('zilla');

    require Dist::Zilla::Chrome::Term;
    Dist::Zilla::Chrome::Term->meta->make_mutable;
    Moose::Util::apply_all_roles('Dist::Zilla::Chrome::Term', 'Dist::Zilla::Role::Chrome::ExtraPrompt');
    Dist::Zilla::Chrome::Term->meta->make_immutable;

    if ($chrome->does('Dist::Zilla::Role::Chrome::ExtraPrompt'))
    {
        $chrome->logger->log_debug('setting up chrome for extra prompt command');
        $chrome->command($payload->{command});
        $chrome->repeat_prompt($payload->{repeat_prompt});
    }

    # WE DO NOT CALL $orig - we will blow up (no zilla, etc)
};
__PACKAGE__->meta->make_immutable;


package Dist::Zilla::Role::Chrome::ExtraPrompt;
{
  $Dist::Zilla::Role::Chrome::ExtraPrompt::VERSION = '0.006';
}
# git description: v0.005-1-g6e3387f

BEGIN {
  $Dist::Zilla::Role::Chrome::ExtraPrompt::AUTHORITY = 'cpan:ETHER';
}
use Moose::Role;
use IPC::Open2;
use File::Spec;
use namespace::autoclean;

has command => (
    is => 'rw', isa => 'Str',
    # no point in saying 'required => 1' - the object is already instantiated
    # by the time we apply our role to it
);
has repeat_prompt => (
    is => 'rw', isa => 'Bool',
);

around [qw(prompt_str prompt_yn)] => sub {
    my $orig = shift;
    my $self = shift;

    if (not $self->command)
    {
        warn "[Chrome::ExtraPrompt] no command to run!\n";
        return $self->$orig(@_);
    }

    open(my $in, '<', File::Spec->devnull);
    open(my $out, '>', File::Spec->devnull);

    my $command = $self->command;
    $command .= ' ' . '"' . $_[0] . '"' if $self->repeat_prompt;

    my $pid = open2($out, $in, $command);

    # when the user responds, kill the process (e.g. shuts up 'say')
    my $input = $self->$orig(@_);
    my $ret = kill 'KILL', $pid;

    return $input;
};
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Karen Etheridge irc

=head1 NAME

Dist::Zilla::Plugin::Chrome::ExtraPrompt - Perform arbitrary commands when Dist::Zilla prompts you

=head1 VERSION

version 0.006

=head1 SYNOPSIS

In your F<~/.dzil/config.ini> (B<NOT> F<dist.ini>):

    [Chrome::ExtraPrompt]
    command = say Dist zilla would like your attention.
    repeat_prompt = 1

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that is loaded from your
F<~/.dzil/config.ini>, which affects the behaviour of prompts within
L<Dist::Zilla> commands. When you are prompted, the specified command is run;
it is killed when you provide prompt input.

I have mine configured as in the synopsis, which uses the C<say> command on
OS X to provide an audio prompt to bring me back to this screen session.

=head1 CONFIGURATION OPTIONS

=over 4

=item * C<command>: the string containing the command and arguments to call.
required.

=item * C<repeat_prompt>: a boolean flag (defaulting to false) that, when set,
appends the prompt string to the command and arguments that are called,
passing as a single (additional?) argument.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Chrome-ExtraPrompt>
(or L<bug-Dist-Zilla-Plugin-Chrome-ExtraPrompt@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Chrome-ExtraPrompt@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
