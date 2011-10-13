#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;

sub compare_attrs {
    my ($rest1, $rest2) = @_;

    my %diff = ();

    my @attrs1 = sort (split / /, $rest1);
    my @attrs2 = sort (split / /, $rest2);

    
#    print STDERR Dumper(\@attrs1, \@attrs2);

    for (my $i = 0; $i < @attrs1; $i++) {
        my ($attr1, $val1) = split /=/, $attrs1[$i];
        my ($attr2, $val2) = split /=/, $attrs2[$i];
        if ($attr1 ne $attr2) {
            die "Different ordering of attrs. Attr1: $attr1, Attr2: $attr2\n";
        }
        if ($val1 ne $val2) {
            $diff{$attr1} = "$val1:$val2";
        }
    }

    return \%diff;
}

sub aggregate_diffs {
    my ($diff_agg, $diff, $id) = @_;

    foreach my $attr (keys %{$diff}) {
        #push @{$diff_agg->{$attr}{$diff->{$attr}}}, $id;
        $diff_agg->{$attr}{$diff->{$attr}}++;
    }
    return $diff_agg;
}

sub read_line {
    my ($handler) = @_;
    
    my $line = <$handler>;
    return (undef, undef) if (!defined $line);
    chomp $line;

    if (($. / 2) % 100 == 0) {
        printf STDERR "Processing the line: %d\r", ($./2);
    }
    
    my ($id, $rest) = split /\t/, $line;
    return ($id, $rest);
}

my $agg_diff = {};

my ($handler1, $handler2);
my ($file1, $file2) = @ARGV;
open $handler1, $file1;
open $handler2, $file2;
    
my ($id1, $rest1) = read_line($handler1);
my ($id2, $rest2) = read_line($handler2);

while (defined $id1 && defined $id2) {
    while (defined $id1 && ($id1 lt $id2)) {
        ($id1, $rest1) = read_line($handler1);
    }
    while (defined $id2 && ($id1 gt $id2)) {
        ($id2, $rest2) = read_line($handler2);
    }
    my ($diff) = compare_attrs($rest1, $rest2);
    $agg_diff = aggregate_diffs($agg_diff, $diff, $id1);

    ($id1, $rest1) = read_line($handler1);
    ($id2, $rest2) = read_line($handler2);
}

close $handler1;
close $handler2;
# just because the processing info
print STDERR "\n";

use Data::Dumper;
print Dumper($agg_diff);
