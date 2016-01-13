#!/usr/bin/bash

function print_table {
    in_filelist=$1
    out_file=$2

    scenario_file=$3

    tmp_dir=../tmp/treex_cr_train/print_table
    treex_run_dir=$tmp_dir/runs
    out_files_dir=$tmp_dir/out

    mkdir -p `dirname $out_file`
    rm -rf $out_files_dir
    mkdir -p $out_files_dir

    treex --workdir "$treex_run_dir"
        Read::Treex from=@$in_filelist
        $scenario_file
}

