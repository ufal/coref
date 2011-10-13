#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

my $num_lines = undef;
GetOptions("number:n" => \$num_lines);

my $anaph = undef;
my $cand_num = undef;
while (my $line = <>) {
    chomp $line;


    if ($line =~ /^\s*$/) {
        $anaph = undef;
        $cand_num = undef;
    }
    elsif ($line =~ /^#(.*)$/) {
        $anaph = $1;
        $cand_num = 1;
    }
    else {
        print STDOUT $anaph;
        if (defined $num_lines) {
            print STDOUT "_$cand_num";
        }
        print STDOUT "\t$line\n";
        $cand_num++;
    }

}
