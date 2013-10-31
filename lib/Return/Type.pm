use 5.008;
use strict;
use warnings;

package Return::Type;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Eval::TypeTiny qw( eval_closure );
use Scope::Upper qw( );
use Types::Standard qw( ArrayRef HashRef );
use Types::TypeTiny qw( to_TypeTiny );

sub _inline_type_check
{
	my $class = shift;
	my ($type, $var, $env) = @_;
	
	return $type->inline_assert($var) if $type->can_be_inlined;
	
	$env->{'$type'} = \$type;
	return sprintf('$type->assert_return(%s);', $var);
}

sub _inline_type_coerce_and_check
{
	my $class = shift;
	my ($type, $var, $env) = @_;
	
	my $coerce = '';
	if ($type->has_coercion and $type->coercion->can_be_inlined)
	{
		$coerce = sprintf('%s = %s;', $var, $type->coercion->inline_coercion($var));
	}
	elsif ($type->has_coercion)
	{
		$env->{'$coercion'} = \( $type->coercion );
		$coerce = sprintf('%s = $coercion->coerce(%s);', $var, $var);
	}
	
	return $coerce . $class->_inline_type_check(@_);
}

sub wrap_sub
{
	my $class = shift;
	my $sub   = $_[0];
	local %_  = @_[ 1 .. $#_ ];
	
	$_{$_}   &&= to_TypeTiny($_{$_}) for qw( list scalar );
	$_{list} ||= ArrayRef[$_{scalar}];
		
	my %env  = ( '$sub' => \$sub );
	my @src  = 'sub { my $wa = wantarray;';
	my $call = '&Scope::Upper::uplevel($sub => (@_) => &Scope::Upper::SUB(&Scope::Upper::SUB))';
	
	my $inline = $_{coerce} ? '_inline_type_coerce_and_check' : '_inline_type_check';
	
	# List context
	push @src, 'if ($wa) {';
	if ( $_{list}->is_a_type_of(HashRef) )
	{
		push @src, 'my $rv = do { use warnings FATAL => qw(misc); +{' . $call . '} };';
		push @src, $class->$inline($_{list}, '$rv', \%env);
		push @src, 'return %$rv;';
	}
	else
	{
		push @src, 'my $rv = [' . $call . '];';
		push @src, $class->$inline($_{list}, '$rv', \%env);
		push @src, 'return @$rv;';
	}
	push @src, '}';
	
	# Scalar context
	push @src, 'elsif (defined $wa) {';
	push @src, 'my $rv = ' . $call . ';';
	push @src, $class->$inline($_{scalar}, '$rv', \%env);
	push @src, 'return $rv;';
	push @src, '}';
	
	# Void context - cannot request a value to check, so check must be skipped
	push @src, 'goto $sub;';
	
	push @src, '}';
	eval_closure(
		source       => \@src,
		environment  => \%env,
	);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Return::Type - specify a return type for a function (optionally with coercion)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Return-Type>.

=head1 SEE ALSO

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

