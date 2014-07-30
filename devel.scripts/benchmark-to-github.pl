#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;

BEGIN {
	my $missing = 0;
	for my $var (qw/ TRAVIS_REPO_SLUG GH_NAME GH_EMAIL GH_TOKEN /) {
		next if defined $ENV{$var};
		warn "missing: $var\n";
		$missing++;
	}
	die "correct environment variables are not set; bailing out"
		if $missing;
};

#################### ACTUAL STUFF WE WANT TO BENCHMARK ####################

package Local::Bench {
	use Types::Standard qw(Int);
	use Return::Type;
	sub example1                  { 42 };
	sub example2 :ReturnType(Int) { 42 };	
}

my @BENCHMARKS = (
	'Simple benchmark' => -1, {
		raw_sub      => q[ my $x = Local::Bench::example1() ],
		type_checked => q[ my $x = Local::Bench::example2() ],
	},
);

###################### POST TO GUTHUB WIKI MECHANICS ######################

use Benchmark qw( cmpthese );

my ($owner, $project) = split "/", $ENV{TRAVIS_REPO_SLUG};

system("rm -fr $project.wiki");
system("git clone https://github.com/$owner/$project.wiki.git");

my $perl       = $ENV{TRAVIS_PERL_VERSION} || $];
my $build_num  = $ENV{TRAVIS_BUILD_NUMBER} || 'dummy';
my $build_id   = $ENV{TRAVIS_BUILD_ID}     || 'dummy';
my $job_num    = $ENV{TRAVIS_JOB_NUMBER}   || 'dummy';
my $job_id     = $ENV{TRAVIS_JOB_ID}       || 'dummy';

my $title = "Travis Build $build_num ($build_id), $job_num ($job_id)";

RESULTS: {
	open my $fh, ">", "$project.wiki/$job_id.md";
	print $fh "# $title\n\n";
	print $fh "[Build log](https://travis-ci.org/$owner/$project/builds/$job_id).\n\n";
	my $old = select($fh);
	while (@BENCHMARKS) {
		my ($name, $times, $cases) = splice(@BENCHMARKS, 0, 3);
		print "## $name\n\n";
		print "```\n";
		cmpthese($times, $cases);
		print "```\n\n";
	}
	select($old);
	close $fh;
}

INDEX: {
	open my $idx, ">>", "$project.wiki/Benchmarks.md";
	print $idx "* [$title]($job_id)\n";
	close $idx;
}

UPLOAD: {
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
}

