=pod

=encoding utf-8

=head1 PURPOSE

Test that Return::Type does add a stack frame saying C<(eval> when
used with a L<Function::Parameters> method, but not when used with
C<< scope_upper => 1 >>.

=head1 AUTHOR

Ed J.

=head1 COPYRIGHT AND LICENCE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
BEGIN {
  plan skip_all => 'no Function::Parameters' unless
    eval { require Function::Parameters; Function::Parameters->import; 1 };
  plan skip_all => 'no Scope::Upper' unless
    eval { require Scope::Upper; Scope::Upper->import; 1 };
}

use Test::Fatal;

my $EVAL_RE = qr/\(eval/;

subtest "no scope_upper means showing (eval...)" => sub
{
	{
	package WithFP;
	use Function::Parameters;
	use Return::Type;
	use Types::Standard -all;
	method s(Str $s) { }
	method s_rt(Str $s) :ReturnType(Any) { }
	}

	unlike exception { WithFP->s(undef); }, $EVAL_RE, 'no RT means no eval';
	like exception { WithFP->s_rt(undef); }, $EVAL_RE, 'with RT means eval';
};

subtest "with scope_upper means not showing (eval...)" => sub
{
	{
	package WithFPandSU;
	use Function::Parameters;
	use Return::Type scope_upper => 1;
	use Types::Standard -all;
	method s(Str $s) { }
	method s_rt(Str $s) :ReturnType(Any) { }
	}

	unlike exception { WithFPandSU->s(undef); }, $EVAL_RE, 'no RT and yes SU means no eval';
	# if use 'exception' for this causes on 5.20 and 5.22: panic: die
	eval { WithFPandSU->s_rt(undef); }; unlike $@, $EVAL_RE, 'with RT and yes SU means no eval';
};

done_testing;
