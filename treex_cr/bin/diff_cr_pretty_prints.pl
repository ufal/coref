#!/usr/bin/env perl

use strict;
use warnings;

sub extract_id {
    my ($str) = @_;
    chomp $str;
    $str =~ s/^.*\///g;
    return $str;
}

sub print_list {
    my (@list) = @_;
    foreach my $inst (@list) {
        print $inst->{cmp} . "\t";
        print $inst->{id} . "\n";
        print $inst->{surf_sent};
        print "1\t" . $inst->{sent1};
        print "2\t" . $inst->{sent2};
        print "\n";
    }
}

my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

open my $fh1, "<", $file1 or die $!;
open my $fh2, "<", $file2 or die $!;

my @better = ();
my @equal_ok = ();
my @equal_err = ();
my @worse = ();

my $addr1 = <$fh1>;
my $addr2 = <$fh2>;
while ($addr1 && $addr2) {
    my $id1 = extract_id($addr1);
    my $id2 = extract_id($addr2);
    if ($id1 ne $id2) {
        print STDERR "The files are incompatible on line $. ($id1 <> $id2)\n";
        exit 1;
    }

    # no need to check the surface sentences since we have already checked the ids
    my $surf_sent = <$fh1>;
    <$fh2>;

    # comparing the labelings
    my $labels1 = <$fh1>;
    my $labels2 = <$fh2>;
    if ($labels1 ne $labels2) {
        my ($err1, $sent1) = split /\t/, $labels1;
        my ($err2, $sent2) = split /\t/, $labels2;

        my $inst = {
            id => $id1,
            surf_sent => $surf_sent,
            sent1 => $sent1,
            sent2 => $sent2,
        };

        if ($err1 eq "ERR:" && $err2 eq "OK:") {
            $inst->{cmp} = "1=ERR < OK=2";
            push @better, $inst;
        }
        elsif ($err1 eq "OK:" && $err2 eq "ERR:") {
            $inst->{cmp} = "1=OK > ERR=2";
            push @worse, $inst;
        }
        elsif ($err1 eq "OK:" && $err2 eq "OK:") {
            $inst->{cmp} = "1= OK =2";
            push @equal_ok, $inst;
        }
        else {
            $inst->{cmp} = "1= ERR =2";
            push @equal_err, $inst;
        }

    }

    # should be empty lines
    <$fh1>; <$fh2>;

    $addr1 = <$fh1>;
    $addr2 = <$fh2>;
}
close $fh1;
close $fh2;

print_list(@better);
print_list(@equal_ok);
print_list(@equal_err);
print_list(@worse);
