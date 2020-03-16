=pod

=encoding utf-8

=head1 PURPOSE

Test that L<Return::Type> package-scoped wrap_sub args works.

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

use Return::Type coerce => 1;

sub foo :ReturnType(Int1) { 3.1415 }

{
	package OtherPackage;

	use Types::Standard qw(Int Num);
	use Return::Type;

	use constant Int1 => Int->plus_coercions(Num, sub { int($_) });

	sub bar :ReturnType(Int1) { 3.1415 }
}

is (
	scalar foo(),
	3,
	'coerce with package-level coercion on',
);

like(
	exception { my $rt = OtherPackage::bar() },
	qr{^Value "3.1415" did not pass type constraint},
	'no coercion in a different package with coercion off',
);

{
	my $wrapped = Return::Type->wrap_sub(
		sub { 3.1415 },
		scalar => Int1,
	);
	is(
		exception { my $rt = $wrapped->() },
		undef,
		'coerce with package-level coercion on calling wrap_sub',
	);
}

{
	use Return::Type::Lexical coerce => 0;

	my $wrapped = Return::Type->wrap_sub(
		sub { 3.1415 },
		scalar => Int1,
	);
	like(
		exception { my $rt = $wrapped->() },
		qr{^Value "3.1415" did not pass type constraint},
		'lexical coerce overrides package coerce',
	);
}

{
	my $wrapped = Return::Type->wrap_sub(
		sub { 3.1415 },
		scalar => Int1,
		coerce => 0,
	);
	like(
		exception { my $rt = $wrapped->() },
		qr{^Value "3.1415" did not pass type constraint},
		'attribute coerce overrides package coerce',
	);
}

done_testing;
