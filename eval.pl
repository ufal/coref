#!/usr/bin/env perl

use warnings;
use strict;

use Getopt::Long;

my $ratio = 0;
GetOptions( "ratio|r"   => \$ratio );

sub _count_fscore {
    my ( $eq, $src, $ref ) = @_;

    my $prec = $src != 0 ? $eq / $src : 0;
    my $reca = $ref != 0 ? $eq / $ref : 0;
    my $fsco = ( $prec + $reca ) != 0 ? 2 * $prec * $reca / ( $prec + $reca ) : 0;

    return ( $prec, $reca, $fsco );
}

my ($tp_total, $src_total, $ref_total) = (0, 0, 0);

while (my $line = <STDIN>) {
    chomp $line;

    my ($tp, $src, $ref) = split /\t/, $line;
    $tp_total += $tp;
    $src_total += $src;
    if (defined $ref) {
        $ref_total += $ref;
    }
}

if ($ratio) {
    printf "Ratio: %.2f%% (%d / %d)\n", $tp_total / $src_total * 100, $tp_total, $src_total;
}
else {
    my ( $prec, $reca, $fsco ) =
        _count_fscore( $tp_total, $src_total, $ref_total );

    printf "P: %.2f%% (%d / %d)\t", $prec * 100, $tp_total, $src_total;
    printf "R: %.2f%% (%d / %d)\t", $reca * 100, $tp_total, $ref_total;
    printf "F: %.2f%%\n",           $fsco * 100;
}
