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
use Types::Standard qw(Int Num);

use constant Int1 => Int->plus_coercions(Num, sub { int($_) });

{
	use Return::Type::Lexical;
	sub foo :ReturnType(Int) { 'not an int' }
	use Return::Type::Lexical check => 0;
	sub bar :ReturnType(Int) { 'not an int' }
	sub baz :ReturnType(Int, check => 1) { 'not an int' }
}

sub qux :ReturnType(Int) { 'not an int' }

{
	package OtherPackage;

	use Types::Standard qw(Int);
	use Return::Type;

	sub muf :ReturnType(Int) { 'not an int' }
}

like(
	exception { my $rt = foo() },
	qr{^Value "not an int" did not pass type constraint},
	'check when enabled lexical',
);

is(
	exception { my $rt = bar() },
	undef,
	'no check when disabled lexical',
);

like(
	exception { my $rt = baz() },
	qr{^Value "not an int" did not pass type constraint},
	'check in attribute overrides lexical',
);

like(
	exception { my $rt = qux() },
	qr{^Value "not an int" did not pass type constraint},
	'check when outside of lexical scope',
);

like(
	exception { my $rt = OtherPackage::muf() },
	qr{^Value "not an int" did not pass type constraint},
	'check when in another package',
);

{
	use Return::Type::Lexical check => 1;

	my $wrapped = Return::Type->wrap_sub(
		sub { 'not an int' },
		scalar => Int,
	);

	like(
		exception { my $rt = $wrapped->() },
		qr{^Value "not an int" did not pass type constraint},
		'check when enabled lexical calling wrap_sub',
	);
}

{
	use Return::Type::Lexical check => 0;

	my $wrapped = Return::Type->wrap_sub(
		sub { 'not an int' },
		scalar => Int,
	);

	is(
		exception { my $rt = $wrapped->() },
		undef,
		'no check when disabled lexical calling wrap_sub',
	);
}

{
	use Return::Type::Lexical check => 1, coerce => 1;

	my $wrapped = Return::Type->wrap_sub(
		sub { shift },
		scalar => Int1,
	);

	is(
		exception { my $rt = $wrapped->(3.141592) },
		undef,
		'coerce with a lexical coercion setting',
	);
}

{
	use Return::Type::Lexical check => 1, coerce => 1;

	my $wrapped = Return::Type->wrap_sub(
		sub { 3.1415 },
		scalar => Int1,
		coerce => 0,
	);
	like(
		exception { my $rt = $wrapped->() },
		qr{^Value "3.1415" did not pass type constraint},
		'attribute coerce overrides lexical coerce calling wrap_sub',
	);
}

done_testing;
