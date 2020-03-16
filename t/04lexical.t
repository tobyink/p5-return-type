=pod

=encoding utf-8

=head1 PURPOSE

Test that L<Return::Type::Lexical> works.

=head1 AUTHOR

Charles McGarvey E<lt>ccm@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Fatal;
use Test::More;
use Types::Standard qw(Int);

{
	use Return::Type::Lexical;
	sub foo :ReturnType(Int) { 'not an int' }
	no Return::Type::Lexical;
	sub bar :ReturnType(Int) { 'not an int' }
}

sub baz :ReturnType(Int) { 'not an int' }

{
	use Return::Type::Lexical check => 0;
	sub qux :ReturnType(Int) { 'not an int' }
}

{
	package OtherPackage;

	use Types::Standard qw(Int);
	use Return::Type;

	sub muf :ReturnType(Int) { 'not an int' }
}

like(
	exception { my $rt = foo() },
	qr{^Value "not an int" did not pass type constraint},
	'return type enforced',
);

is(
	exception { my $rt = bar() },
	undef,
	'return type not enforced when unimport is called',
);

like(
	exception { my $rt = baz() },
	qr{^Value "not an int" did not pass type constraint},
	'return type enforced again when outside previous scope',
);

is(
	exception { my $rt = qux() },
	undef,
	'return type not enforced import called with check to 0',
);

like(
	exception { my $rt = OtherPackage::muf() },
	qr{^Value "not an int" did not pass type constraint},
	'return type enforced when using Return::Type directly in another package',
);

(sub {
	use Return::Type::Lexical check => 1;

	my $wrapped = Return::Type->wrap_sub(
		sub { 'not an int' },
		scalar => Int,
	);

	like(
		exception { my $rt = $wrapped->() },
		qr{^Value "not an int" did not pass type constraint},
		'return type enforced when wrapping at runtime',
	);
})->();

(sub {
	use Return::Type::Lexical check => 0;

	my $wrapped = Return::Type->wrap_sub(
		sub { 'not an int' },
		scalar => Int,
	);

	is(
		exception { my $rt = $wrapped->() },
		undef,
		'return type not enforced when wrapping at runtime',
	);
})->();

done_testing;
