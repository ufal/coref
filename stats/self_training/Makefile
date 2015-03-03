SHELL=/bin/bash

OUTPUT_DIR=out

RUN_DIR=$(CZENG_COREF_DIR)/tmp/ml

RUN_DIR_LIST=run_2014-07-23_23-41-59.self-training.delible.loss_1 run_2014-07-23_23-42-33.self-training.delible.loss_0 run_2014-07-23_23-42-48.self-training.delible.loss_-1 run_2014-07-23_23-42-59.self-training.delible.loss_-2 run_2014-07-23_23-43-08.self-training.delible.loss_-3
ITER_DIRS=iter_001 iter_002 iter_003 iter_004 iter_005 iter_006 iter_007 iter_008 iter_009 iter_010

train_data_sizes :
	for i in $(RUN_DIR_LIST); do \
		echo -en "$$i\t"; \
		for j in $(ITER_DIRS); do \
			res=`zcat tmp/ml/$$i/001.134ca.mlmethod/$$j/data/train.czeng_0.en.analysed.part_0* | grep "^$$" | wc -l`; \
			echo -ne "$$res\t"; \
		done; \
		echo; \
	done > $(OUTPUT_DIR)/self_training.data_size.instances &
	for i in $(RUN_DIRS); do \
		echo -en "$$i\t"; \
		for j in $(ITER_DIRS); do \
			res=`zcat tmp/ml/$$i/001.134ca.mlmethod/$$j/data/train.czeng_0.en.analysed.part_0* | wc -l`; \
			echo -ne "$$res\t"; \
		done; \
		echo; \
	done > $(OUTPUT_DIR)/self_training.data_size.lines &

RUN_DIR_LIST2=self-training.delible.avg_diff_loss_0.run_2014-08-15_17-11-47 self-training.delible.avg_diff_loss_-1.run_2014-08-15_17-11-57 self-training.delible.avg_diff_loss_-2.run_2014-08-15_17-12-07 self-training.delible.avg_diff_loss_-3.run_2014-08-15_17-12-17 self-training.delible.avg_diff_loss_-4.run_2014-08-15_17-12-27 self-training.delible.avg_diff_loss_-5.run_2014-08-15_17-12-37 self-training.delible.avg_diff_loss_-6.run_2014-08-15_17-12-47 self-training.delible.avg_diff_loss_-7.run_2014-08-15_17-12-57 self-training.delible.avg_diff_loss_-8.run_2014-08-15_17-13-07 self-training.delible.diff_loss_0.run_2014-08-15_17-32-25 self-training.delible.diff_loss_-1.run_2014-08-15_17-32-35 self-training.delible.diff_loss_-2.run_2014-08-15_17-32-45 self-training.delible.diff_loss_-3.run_2014-08-15_17-32-55 self-training.delible.diff_loss_-4.run_2014-08-15_17-33-05 self-training.delible.diff_loss_-5.run_2014-08-15_17-33-15 self-training.delible.diff_loss_-6.run_2014-08-15_17-33-25 self-training.delible.min_loss_0.run_2014-08-15_18-24-18 self-training.delible.min_loss_1.run_2014-08-15_18-24-08 self-training.delible.min_loss_-1.run_2014-08-15_18-24-28 self-training.delible.min_loss_2.run_2014-08-15_18-23-58 self-training.delible.min_loss_-2.run_2014-08-15_18-24-38 self-training.delible.min_loss_3.run_2014-08-15_18-23-48 self-training.delible.min_loss_-3.run_2014-08-15_18-24-48 self-training.delible.min_loss_-4.run_2014-08-15_18-24-58

train_data_sizes2 :
	for i in $(RUN_DIR_LIST2); do \
		echo -ne $$i'\t'; \
		cat $(CZENG_COREF_DIR)/tmp/ml/$$i/002.c0afe.mlmethod/log/mlmethod_exper.c0afe.* | grep "number of examples per pass" | sed -n '4~3p' | cut -f7 -d' ' | perl -e 'my @items = (); while (<STDIN>) {chomp $$_; push @items, $$_;} print join "\t", @items; print "\n";'; \
	done > $(OUTPUT_DIR)/self_training.data_size2.instances

RESULT_DIR=$(RUN_DIR)/run_2014-08-12_16-29-39/001.134ca.mlmethod/iter_000/result

losses_vs_correct :
	paste $(RESULT_DIR)/dev.pcedt_bi.en.analysed.train.pcedt_bi.en.analysed.vw.ranking.res $(RESULT_DIR)/unlabeled.dev.pcedt_bi.en.analysed.train.pcedt_bi.en.analysed.vw.ranking.res | \
	cut -d' ' -f2 | sed 's/-1//' | \
	perl -e 'my $$i = 1; while (<STDIN>) { if ($$_ =~ /^\s+$$/) {$$i = 1; print $$_; next;} print "$$i\t$$_"; $$i++; }' | \
	perl -ne 'if ($$_ =~ /^\s*$$/) {print $$_; next;} ($$p, $$t, $$c) = split /\t/, $$_; %ok = map {$$_ => 1} split /,/, $$t; print ($$ok{$$p} ? 1 : 0); print "\t$$c";' \
	> $(OUTPUT_DIR)/dev.iter_000.losses_vs_correct
