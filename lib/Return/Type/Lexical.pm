use 5.008;
use strict;
use warnings;

package Return::Type::Lexical;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use parent 'Return::Type';

sub import {
	my $class = shift;
	my (%args) = @_;

	$^H{'Return::Type::Lexical/check'} = exists $args{check} && !$args{check} ? 0 : 1;
	$^H{'Return::Type::Lexical/wrap_sub_args/coerce'} = $args{coerce} if defined $args{coerce};
	$^H{'Return::Type::Lexical/wrap_sub_args/coerce_list'} = $args{coerce_list} if defined $args{coerce_list};
	$^H{'Return::Type::Lexical/wrap_sub_args/coerce_scalar'} = $args{coerce_scalar} if defined $args{coerce_scalar};
}

sub unimport {
	delete $^H{'Return::Type::Lexical/check'};
	delete $^H{'Return::Type::Lexical/wrap_sub_args/coerce'};
	delete $^H{'Return::Type::Lexical/wrap_sub_args/coerce_list'};
	delete $^H{'Return::Type::Lexical/wrap_sub_args/coerce_scalar'};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Return::Type::Lexical - same thing as Return::Type, but lexical

=head1 SYNOPSIS

   use Return::Type::Lexical;
   use Types::Standard qw(Int);

   sub foo :ReturnType(Int) { return "not an int" }

   {
      use Return::Type::Lexical check => 0;
      sub bar :ReturnType(Int) { return "not an int" }
      sub baz :ReturnType(Int, check => 1) { return "not an int" }
   }

   my $foo = foo();    # throws an error
   my $bar = bar();    # returns "not an int"
   my $baz = baz();    # throws an error

   # Can also be used with Devel::StrictMode to only perform
   # type checks in strict mode:

   use Devel::StrictMode;
   use Return::Type::Lexical check => STRICT;

=head1 DESCRIPTION

This module works just like L<Return::Type>, but type-checking can be
enabled and disabled within lexical scopes.

There is no runtime penalty when type-checking is disabled.

=head1 METHODS

The C<import> method supports the C<check> attribute to set whether or
not types are checked.

=head1 CAVEATS

Disabling checks also disables coercions (if any).

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Return-Type>.

=head1 SUPPORT

B<< IRC: >> support is available through in the I<< #moops >> channel
on L<irc.perl.org|http://www.irc.perl.org/channels.html>.

=head1 SEE ALSO

L<Return::Type>

=head1 AUTHOR

Charles McGarvey E<lt>ccm@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

