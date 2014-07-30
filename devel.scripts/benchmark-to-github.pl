#!/usr/bin/env perl

use 5.006;
use strict;
use warnings;

BEGIN {
	package Benchmark::Report::GitHub;
	
	use strict;
	use warnings;
	
	my @attributes = qw/ travis_repo_slug gh_name gh_email gh_token /;
	
	sub new {
		my $class = shift;
		my $self  = bless +{ @_ }, $class;
		defined($self->{$_}) || die("missing required attribute: $_")
			for @attributes;
		return $self;
	}
	
	sub new_from_env {
		my $class = shift;
		
		my $missing = 0;
		for my $var (qw/ TRAVIS_REPO_SLUG GH_NAME GH_EMAIL GH_TOKEN /) {
			next if defined $ENV{$var};
			warn "missing: $var\n";
			$missing++;
		}
		die "correct environment variables are not set; bailing out"
			if $missing;
		
		$class->new(map +( $_ => $ENV{uc($_)} ), @attributes);
	}
	
	sub add_benchmark {
		my $self = shift;
		@_ == 3 or die("too many or too few arguments");
		push @{ $self->{benchmarks} ||= [] }, @_;
		return $self;
	}
	
	sub publish {
		my $self = shift;
		my %args = @_;
		
		my ($owner, $project) = split "/", $self->{travis_repo_slug};
		
		my @benchmarks = @{$self->{benchmarks}}
			or die "did you forget something?";
		
		system("rm -fr $project.wiki");
		system("git clone https://github.com/$owner/$project.wiki.git");
		
		my $perl = $args{perl_version} || $ENV{TRAVIS_PERL_VERSION} || $];
		my ($build_num, $build_id, $job_num, $job_id) = map {
			$args{$_} || $ENV{ "TRAVIS_" . uc($_) } || 'unknown'
		} qw( build_number build_id job_number job_id );
		
		my $page    = $args{page}       || "Benchmark_$job_id";
		my $title   = $args{page_title} || "Travis Job $job_num";
		my $idxpage = $args{index_page} || "Benchmarks";
		
		require Benchmark;
		require Cwd;
		require File::Path;
		
		RESULTS: {
			open my $fh, ">", "$project.wiki/$page.md";
			print $fh "# $title\n\n";
			print $fh "[Build log](https://travis-ci.org/$owner/$project/builds/$job_id).\n\n";
			my $old = select($fh);
			while (@benchmarks) {
				my ($name, $times, $cases) = splice(@benchmarks, 0, 3);
				print "## $name\n\n";
				print "```\n";
				Benchmark::cmpthese($times, $cases);
				print "```\n\n";
			}
			select($old);
			close $fh;
		}
		
		INDEX: {
			open my $idx, ">>", "$project.wiki/$idxpage.md";
			print $idx "* [$title]($page)\n";
			close $idx;
		}
		
		UPLOAD: {
			my $orig = Cwd::cwd();
			chdir "$project.wiki";
			system("git config user.name '$ENV{GH_NAME}'");
			system("git config user.email '$ENV{GH_EMAIL}'");
			system("git config credential.helper 'store --file=.git/credentials'");
			open my $cred, '>', '.git/credentials';
			print $cred "https://$ENV{GH_TOKEN}:\@github.com\n";
			close $cred;
			system("git add .");
			system("git commit -a -m 'benchmarks for $job_num'");
			system("git push --all");
			system("rm '.git/credentials'");
			chdir($orig);
			File::Path::remove_tree("$project.wiki");
		}
		
		return "https://github.com/$owner/$project/wiki/$page";
	}	
};

#################### ACTUAL STUFF WE WANT TO BENCHMARK ####################

{
	package Local::Bench;
	use Types::Standard qw(Int);
	use Return::Type;
	sub example1                  { 42 };
	sub example2 :ReturnType(Int) { 42 };
}

print(
	Benchmark::Report::GitHub
		-> new_from_env
		-> add_benchmark(
			'Simple benchmark', -1, {
				raw_sub      => q[ my $x = Local::Bench::example1() ],
				type_checked => q[ my $x = Local::Bench::example2() ],
			},
		)
		-> publish,
	"\n",
);