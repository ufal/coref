#!/usr/bin/env perl

use strict;
use utf8;
use warnings;

use AI::MaxEntropy;
use Data::Dumper;
use Getopt::Long;

my $USAGE = <<"USAGE_END";
Usage: $0 [-e <value_of_epsilon>] [-n <comma-separated_list_of_feature_names>] <resulting_model>
USAGE_END

my $y_idx = 0;

if (@ARGV < 1) {
    print STDERR $USAGE;
    exit;
}

my $epsilon = 0.1;
my $feat_names;
GetOptions( "epsilon|e=f"   => \$epsilon,
            "names|n=s@"     => \$feat_names,
);
if (defined $feat_names) {
    $feat_names = [ split /,/, (join ',', @$feat_names) ];
}

# create a maximum entropy learner
my $me = AI::MaxEntropy->new(
    algorithm => {
        progress_cb => 'verbose',
        epsilon => $epsilon
    }
); 

my $i = 0;
while (my $line = <STDIN>) {

    # print progress
    $i++;
    if ($i % 10000 == 0) {
        printf STDERR "Showing the instances to maximum entropy method. Processed lines: %d\r", $i;
    }

    chomp $line;
    my @items = split /\t/, $line;
    if (!defined $feat_names) {
        $feat_names = [ 0 .. (scalar @items)-1 ];
    }
    my %instance = map {$feat_names->[$_] => $items[$_]} (0 .. (scalar @items)-1);
    my $y_value = delete $instance{$feat_names->[$y_idx]};

    #print STDERR Dumper(\%instance);
    #print STDERR "VAL: $y_value\n";

    $me->see(\%instance => $y_value);
}

print STDERR "Learning a maximum entropy model...\n";
my $model = $me->learn();
print STDERR "Saving the model...\n";
$model->save($ARGV[0]);
