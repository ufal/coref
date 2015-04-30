#!/bin/bash

language=$1
data_list=$2
d=$3

d_no_space=`echo $d | sed 's/ /_/g'`
last_n=`find tmp/cr_pretty_print -maxdepth 1 -mindepth 1 -path "*/run*" -type d | cut -f3 -d'/' | cut -f1 -d'_' | cut -f2 -d'-' | sort | tail -n1` || 000
next_n=`perl -e 'printf "%03d", $ARGV[0]+1' $last_n`

tmp_dir=tmp/cr_pretty_print/$next_n'_'`date +%Y-%m-%d_%H-%M-%S`'_'$$'_'$d_no_space
mkdir -p $tmp_dir

mkdir -p $tmp_dir/trees
mkdir -p $tmp_dir/trees.del

mkdir -p $tmp_dir/parts
treex -p --jobs 50 -L$language -Ssrc \
    Read::Treex from=@$data_list \
    Util::Eval tnode='if ($tnode->wild->{coref_diag}{is_anaph}) { my @antes = $tnode->get_coref_nodes; $_->wild->{coref_diag}{sys_ante_for}{$tnode->id} = 1 foreach (@antes) }' \
    Coref::RemoveLinks \
    Write::Treex path="$tmp_dir/trees.del" \
    T2T::CopyCorefFromAlignment selector=ref \
    Util::Eval tnode='my @antes = $tnode->get_coref_chain; $_->wild->{coref_diag}{key_ante_for}{$tnode->id} = 1 foreach (@antes)' \
    Write::Treex path="$tmp_dir/trees" \
    Coref::PrettyPrint path="$tmp_dir/parts"
find $tmp_dir/parts -name '*.txt' | sort | xargs cat > $tmp_dir/all.txt
cat $tmp_dir/all.txt | \
    tr '\n' '\t' | \
    sed 's/\t\t/\n/g' | \
    sort -k3,3 -t'	' | \
    sed 's/$/\n/' | \
    sed 's/ERR:\t/ERR: /g' | \
    sed 's/OK:\t/OK: /g' | \
    sed 's/\t/\n/g' | \
    sed 's/ERR: /ERR:\t/g' | \
    sed 's/OK: /OK:\t/g' > $tmp_dir/all.sorted.txt

echo "All coref data pretty printed in: $tmp_dir/all.txt"
echo "Sorted with the errors first: $tmp_dir/all.sorted.txt"
