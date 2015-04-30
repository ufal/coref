#!/bin/bash

language=$1
data_list=$2

tmp_dir=tmp/cr_pretty_print/`date +%Y-%m-%d_%H-%M-%S`_$$
mkdir -p $tmp_dir

#    Write::Treex path="$tmp_dir/trees"
#mkdir -p $tmp_dir/trees

mkdir -p $tmp_dir/parts
treex -L$language -Sref \
    Read::Treex from=@$data_list \
    Util::Eval tnode='my @antes = $tnode->get_coref_nodes; $_->wild->{coref_diag}{key_ante_for}{$tnode->id} = 1 foreach (@antes)' \
    Coref::RemoveLinks \
    T2T::CopyCorefFromAlignment selector=src \
    Util::Eval tnode='my @antes = $tnode->get_coref_nodes; $_->wild->{coref_diag}{sys_ante_for}{$tnode->id} = 1 foreach (@antes)' \
    Coref::PrettyPrint path="$tmp_dir/parts"
find $tmp_dir/parts -name '*.txt' | sort | xargs cat > $tmp_dir/all.txt
