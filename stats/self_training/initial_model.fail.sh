#!/bin/bash

tmp_dir=tmp/initial_model.fail

initial_data=data/train.pcedt_bi.en.analysed.table
additional_data=data/train.czeng_0.en.analysed.iter000.table
test_data=data/dev.pcedt_bi.en.analysed.table

output_dir=out
output_file=$output_dir/initial_model.fail.table.txt

mkdir -p $tmp_dir 

echo -n "Initial data (30 passes)" > $output_file
zcat $initial_data | cut -f2 --complement | vw -f $tmp_dir/init30.model -b 20 --csoaa_ldf mc --loss_function logistic --passes 30 --holdout_off -k --cache_file $tmp_dir/vw.cache --save_resume
zcat $test_data | cut -f2 --complement | vw -t -i $tmp_dir/init30.model -r $tmp_dir/init30.result
cat $tmp_dir/init30.result | $ML_FRAMEWORK_DIR/scripts/results_to_triples.pl --ranking | $ML_FRAMEWORK_DIR/scripts/eval.pl --acc --prf | cut -f1 -d' ' | perl -ne 'chomp $_; print "\t$_";' >> $output_file
echo >> $output_file

echo -n "Initial data (30 passes) + Additional data (1 pass)" >> $output_file
zcat $additional_data | cut -f2 --complement | vw -i $tmp_dir/init30.model -f $tmp_dir/init30+add1.model -b 20 --loss_function logistic --passes 1 --holdout_off -k --cache_file $tmp_dir/vw.cache --save_resume
zcat $test_data | cut -f2 --complement | vw -t -i $tmp_dir/init30+add1.model -r $tmp_dir/init30+add1.result
cat $tmp_dir/init30+add1.result | $ML_FRAMEWORK_DIR/scripts/results_to_triples.pl --ranking | $ML_FRAMEWORK_DIR/scripts/eval.pl --acc --prf | cut -f1 -d' ' | perl -ne 'chomp $_; print "\t$_";' >> $output_file
echo >> $output_file

echo -n "Initial data (30 passes) + Additional data (30 passes)" >> $output_file
zcat $additional_data | cut -f2 --complement | vw -i $tmp_dir/init30.model -f $tmp_dir/init30+add30.model -b 20 --loss_function logistic --passes 30 --holdout_off -k --cache_file $tmp_dir/vw.cache --save_resume
zcat $test_data | cut -f2 --complement | vw -t -i $tmp_dir/init30+add30.model -r $tmp_dir/init30+add30.result
cat $tmp_dir/init30+add30.result | $ML_FRAMEWORK_DIR/scripts/results_to_triples.pl --ranking | $ML_FRAMEWORK_DIR/scripts/eval.pl --acc --prf | cut -f1 -d' ' | perl -ne 'chomp $_; print "\t$_";' >> $output_file
echo >> $output_file

echo -n "Initial data + Additional data (30 passes)" >> $output_file
zcat $initial_data $additional_data | cut -f2 --complement | vw -f $tmp_dir/init+add30.model -b 20 --csoaa_ldf mc --loss_function logistic --passes 30 --holdout_off -k --cache_file $tmp_dir/vw.cache --save_resume
zcat $test_data | cut -f2 --complement | vw -t -i $tmp_dir/init+add30.model -r $tmp_dir/init+add30.result
cat $tmp_dir/init+add30.result | $ML_FRAMEWORK_DIR/scripts/results_to_triples.pl --ranking | $ML_FRAMEWORK_DIR/scripts/eval.pl --acc --prf | cut -f1 -d' ' | perl -ne 'chomp $_; print "\t$_";' >> $output_file
echo >> $output_file

rm -rf $tmp_dir
