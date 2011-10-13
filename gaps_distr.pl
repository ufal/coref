#!/usr/bin/perl

use strict;
use warnings;

my $prev_num = undef;
my $prev_type = undef;

my %gaps = ();
my %total = ();

while (<>) {
    chomp $_;
    my ($num, $type) = split /\t/, $_;
    if (defined $prev_num && defined $prev_type && ($type eq $prev_type)) {
        my $gap_size = $num - $prev_num;
        $gaps{$type}{$gap_size}++;
        $total{$type}++;
    }
    $prev_num = $num;
    $prev_type = $type;
}

foreach my $type (keys %gaps) {
    print "$type\n";
    print "----------\n";

    my @sorted_gaps = sort {$gaps{$type}{$b} <=> $gaps{$type}{$a}}
        keys %{$gaps{$type}};
    foreach my $gap (@sorted_gaps) {
        printf "$gap\t$gaps{$type}{$gap}\t%.2f%%\n",
            $gaps{$type}{$gap}/$total{$type}*100;
    }
    print "\n";
}
