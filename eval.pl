#!/usr/bin/env perl

use warnings;
use strict;

use Getopt::Long;

my $segm = 0;
GetOptions( "segm|s"   => \$segm );

sub _add_to_array {
    my ($array, $line) = @_;

    my @vals = split /\t/, $line;
    
    if (!$array) {
        return \@vals;
    }
    for (my $i = 0; $i < @$array; $i++) {
        $array->[$i] += $vals[$i];
    }
    return $array;
}

sub _count_fscore {
    my ( $eq, $src, $ref ) = @_;

    my $prec = $src != 0 ? $eq / $src : 0;
    my $reca = $ref != 0 ? $eq / $ref : 0;
    my $fsco = ( $prec + $reca ) != 0 ? 2 * $prec * $reca / ( $prec + $reca ) : 0;

    return ( $prec, $reca, $fsco );
}



my ($tp_total, $src_total, $ref_total) = (0, 0, 0);

my $array = undef;

while (my $line = <STDIN>) {
    chomp $line;

    $array = _add_to_array($array, $line);
}

if ($segm) {
    printf "SRC: %d, REF_NAIVE: %d, REF_RANDOMIZED: %d\n", $array->[0], $array->[1], $array->[2];
}
else {
    my ( $prec, $reca, $fsco ) =
        _count_fscore( @$array );
    ($tp_total, $src_total, $ref_total) = @$array;

    printf "P: %.2f%% (%d / %d)\t", $prec * 100, $tp_total, $src_total;
    printf "R: %.2f%% (%d / %d)\t", $reca * 100, $tp_total, $ref_total;
    printf "F: %.2f%%\n",           $fsco * 100;
}
