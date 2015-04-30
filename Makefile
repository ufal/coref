SHELL = bash

DATA_SET = sample
#DATA_SOURCE = pdt_bridging
ANOT = analysed
#ANOT = gold
#DATA_SET = dev

LANGUAGE=cs
LANGUAGE_UPPER := $(shell echo ${LANGUAGE} | tr 'a-z' 'A-Z')

############################### DATA SOURCES #################################

DATA_SOURCE = pdt
ifeq ($(LANGUAGE), en)
DATA_SOURCE = pedt
endif

############################### DIRECTORIES #################################

DATA_DIR = data/$(LANGUAGE)

ANALYSED_DIR = $(DATA_DIR)/analysed/$(DATA_SOURCE)/$(DATA_SET)

TRAIN_TABLE_DIR = $(DATA_DIR)/train_table/$(ANOT)/$(DATA_SOURCE)/$(DATA_SET)
TRAIN_TABLE_GOLD_DIR = $(DATA_DIR)/train_table/gold/$(DATA_SOURCE)/$(DATA_SET)
TRAIN_TABLE_ANALYSED_DIR = $(DATA_DIR)/train_table/analysed/$(DATA_SOURCE)/$(DATA_SET)

MODEL_DIR = $(DATA_DIR)/model/$(ANOT)/$(DATA_SOURCE)/$(DATA_SET)

RESOLVED_DIR = $(DATA_DIR)/resolved/$(ANOT)/$(DATA_SOURCE)/$(DATA_SET)
RESOLVED_GOLD_DIR = $(DATA_DIR)/resolved/gold/$(DATA_SOURCE)/$(DATA_SET)
RESOLVED_ANALYSED_DIR = $(DATA_DIR)/resolved/analysed/$(DATA_SOURCE)/$(DATA_SET)

TMP_DIR = tmp

############################### EXPERIMENT IDS ##############################

ID_ANALYSED := $(shell cat $(ANALYSED_DIR)/last_id 2> /dev/null || echo 0000)
ID_TRAIN_TABLE := $(shell cat $(TRAIN_TABLE_DIR)/last_id 2> /dev/null || echo 0000)
ID_RESOLVED := $(shell cat $(RESOLVED_DIR)/last_id 2> /dev/null || echo 0000)

ifeq ($(ANOT), gold)
ID_ANALYSED := 0001
endif

ID_ANALYSED_NEXT := $(shell expr $(ID_ANALYSED) + 1 | perl -ne 'printf "%.4d", $$_;' )
ID_TRAIN_TABLE_NEXT := $(shell expr $(ID_TRAIN_TABLE) + 1 | perl -ne 'printf "%.4d", $$_;')
ID_RESOLVED_NEXT := $(shell expr $(ID_RESOLVED) + 1 | perl -ne 'printf "%.4d", $$_;')

print_dummy :
	@echo $(ID_ANALYSED)
	@echo $(ID_TRAIN_TABLE)
	@echo $(ID_RESOLVED)
	@echo $(ID_ANALYSED_NEXT)
	@echo $(ID_TRAIN_TABLE_NEXT)
	@echo $(ID_RESOLVED_NEXT)
	@echo $(LANGUAGE)

print_dummy-%:
	@make -s print_dummy ID_ANALYSED=`echo $* | cut -d: -f1` ID_TRAIN_TABLE=`echo $* | cut -d: -f2` ID_RESOLVED=`echo $* | cut -d: -f3`

############################################################################

RUNS_DIR = runs

DATE := $(shell date +%Y-%m-%d_%H-%M-%S)
TMT_VERSION := $(shell echo `git rev-parse --abbrev-ref HEAD`:`git rev-parse HEAD | cut -c 1-10`)
NEW_NUM  := $(shell perl -e '$$m=0; for(<$(RUNS_DIR)/*>){/\/(\d+)_/ and $$1 > $$m and $$m=$$1;} printf "%03d", $$m+1;')
NEW_TRY  := $(RUNS_DIR)/$(NEW_NUM)_$(DATE)_$(SHORT_SCEN)


ANAPHOR_AS_CANDIDATE = 1
ifeq (${ANAPHOR_AS_CANDIDATE}, 1)
JOINT_SUFFIX = .joint
endif

JOBS_NUM = 50

DATA_SET_PREFIX := $(shell echo ${DATA_SET} | cut -d'_' -f1)
ifeq ($(DATA_SET_PREFIX), train)
JOBS_NUM = 100
endif

ifeq (${LANGUAGE}, en)
ifeq ($(DATA_SOURCE), pedt)
  PREPROC_BLOCKS = W2A::EN::SetAfunAuxCPCoord W2A::EN::SetAfun A2T::EN::SetGrammatemes
  DELETE_TRACES = A2W::EN::DeleteTracesFromSentence
endif
#ifneq (${ANAPHOR_AS_CANDIDATE}, 1)
  IS_REFER_BLOCK = A2T::EN::MarkReferentialIt resolver_type=nada
#endif
endif

READ_GOLD_DATA_BLOCK = Read::PDT from=@data/${LANGUAGE}/${DATA_SET}.${DATA_SOURCE}.gold.list schema_dir=/net/work/people/mnovak/schemas
ifeq ($(DATA_SOURCE), pcedt)
  READ_GOLD_DATA_BLOCK = Read::Treex from=@data/${LANGUAGE}/${DATA_SET}.${DATA_SOURCE}.gold.list
endif

LRC=1
ifeq ($(LRC), 1)
CLUSTER_FLAGS = -p --qsub '-hard -l mem_free=2G -l act_mem_free=2G -l h_vmem=2G' --jobs ${JOBS_NUM} --priority -100
endif



################################ ANALYSE ####################################

analyse_all :
	@make analyse DATA_SET=train
	@make analyse DATA_SET=dev
	@make analyse DATA_SET=eval
analyse:
	@make analyse_data_set ID_ANALYSED=$(ID_ANALYSED_NEXT)
	
analyse_data_set : $(ANALYSED_DIR)/$(ID_ANALYSED)/list

MONO_ALIGN=1
ifeq ($(MONO_ALIGN), 1)
MONO_ALIGN_BLOCK = Util::SetGlobal language=${LANGUAGE} selector=ref \
	Align::A::MonolingualGreedy to_language=${LANGUAGE} to_selector=src \
	Align::T::CopyAlignmentFromAlayer to_language=${LANGUAGE} to_selector=src align_type=monolingual del_prev_align=0 \
	Align::T::AlignGeneratedNodes to_language=${LANGUAGE} to_selector=src
endif

#data/${LANGUAGE}/${DATA_SET}.${DATA_SOURCE}.gold.list
$(ANALYSED_DIR)/$(ID_ANALYSED)/list :
	mkdir -p $(ANALYSED_DIR)/$(ID_ANALYSED)
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} \
	$(READ_GOLD_DATA_BLOCK) \
	Util::Eval language=cs zone='$$zone->set_selector("ref");' \
	Util::Eval language=en zone='$$zone->set_selector("ref");' \
	Util::SetGlobal language=${LANGUAGE} selector=ref \
	A2W::Detokenize \
	${DELETE_TRACES} \
	Util::SetGlobal language=${LANGUAGE} selector=src \
	W2W::CopySentence source_language=${LANGUAGE} source_selector=ref \
	scenarios/analysis.${LANGUAGE}.scen \
	$(MONO_ALIGN_BLOCK) \
	Write::Treex clobber=1 storable=1 path=$(ANALYSED_DIR)/$(ID_ANALYSED)
	find $(ANALYSED_DIR)/$(ID_ANALYSED) -name "*.streex" | sed 's/^.*\/\([^\/]*\)$$/\1/' | sort > $(ANALYSED_DIR)/$(ID_ANALYSED)/list
	perl -e 'print join("\t", "$(ID_ANALYSED)", "$(DATE)", "$(TMT_VERSION)", '\''${DESC}'\''); print "\n";' >> $(ANALYSED_DIR)/history
	echo $(ID_ANALYSED) > $(ANALYSED_DIR)/last_id


###################### PREPARE TRAIN TABLE #############################

ID_TRAIN_TABLE_COMBINED=$(ID_ANALYSED).$(ID_TRAIN_TABLE)

train_table:
	@make train_table_data_set ID_TRAIN_TABLE=$(ID_TRAIN_TABLE_NEXT)

train_table_data_set: $(TRAIN_TABLE_DIR)/$(ID_TRAIN_TABLE_COMBINED).table

#-------------------- GOLD -------------------------------

$(TRAIN_TABLE_GOLD_DIR)/$(ID_TRAIN_TABLE_COMBINED).table : data/${LANGUAGE}/${DATA_SET}.${DATA_SOURCE}.gold.list
	mkdir -p $(TRAIN_TABLE_GOLD_DIR)
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} \
	${READ_GOLD_DATA_BLOCK} \
	${PREPROC_BLOCKS} \
	A2T::${LANGUAGE_UPPER}::MarkClauseHeads \
	A2T::SetDocOrds \
	T2T::SetClauseNumber \
	${IS_REFER_BLOCK} \
	Print::${LANGUAGE_UPPER}::TextPronCorefData anaphor_as_candidate=${ANAPHOR_AS_CANDIDATE} \
		> $(TRAIN_TABLE_GOLD_DIR)/$(ID_TRAIN_TABLE_COMBINED).table
	perl -e 'print join("\t", "$(ID_TRAIN_TABLE_COMBINED)", "$(DATE)", "ANAPHOR_AS_CANDIDATE=$(ANAPHOR_AS_CANDIDATE)", "$(TMT_VERSION)", '\''${DESC}'\''); print "\n";' >> $(TRAIN_TABLE_DIR)/history
	echo $(ID_TRAIN_TABLE) > $(TRAIN_TABLE_DIR)/last_id

#-------------------- ANALYSED -------------------------------
	#Util::Eval tnode=`cat scripts/copy_grams` selector=ref \

CLEAN_DATA_SOURCE := $(shell echo $(DATA_SOURCE) | sed 's/_.*$$//')
ifeq ($(CLEAN_DATA_SOURCE), czeng)
UNLABELED_FLAG = labeled=0
endif

$(TRAIN_TABLE_ANALYSED_DIR)/$(ID_TRAIN_TABLE_COMBINED).table : $(ANALYSED_DIR)/$(ID_ANALYSED)/list
	mkdir -p $(TRAIN_TABLE_ANALYSED_DIR)
	rm -rf tmp/data_table/*.$(DATA_SET).$(DATA_SOURCE).$(LANGUAGE).txt
	treex ${CLUSTER_FLAGS} --workdir "tmp/treex_runs/run_{NNN}-{XXXX}" \
		Read::Treex from=@$(ANALYSED_DIR)/$(ID_ANALYSED)/list \
		scenarios/$(CLEAN_DATA_SOURCE).$(LANGUAGE).before_data_table.scen \
		Util::SetGlobal language=$(LANGUAGE) \
		Print::${LANGUAGE_UPPER}::TextPronCorefData $(COREF_PRINTER_PARAMS) $(UNLABELED_FLAG) anaphor_as_candidate=${ANAPHOR_AS_CANDIDATE} to='.' substitute='{^.*/(.*)}{tmp/data_table/$$1.$(DATA_SET).$(DATA_SOURCE).$(LANGUAGE).txt}'
	find tmp/data_table -path "*.$(DATA_SET).$(DATA_SOURCE).$(LANGUAGE).txt" | sort | xargs cat | gzip -c > $(TRAIN_TABLE_ANALYSED_DIR)/$(ID_TRAIN_TABLE_COMBINED).table
	-rm $(DATA_DIR)/$(DATA_SET).$(DATA_SOURCE).$(LANGUAGE).$(ANOT).table
	ln -s $(PWD)/$(TRAIN_TABLE_ANALYSED_DIR)/$(ID_TRAIN_TABLE_COMBINED).table $(DATA_DIR)/$(DATA_SET).$(DATA_SOURCE).$(LANGUAGE).$(ANOT).table
	perl -e 'print join("\t", "$(ID_TRAIN_TABLE_COMBINED)", "$(DATE)", "ANAPHOR_AS_CANDIDATE=$(ANAPHOR_AS_CANDIDATE)", "$(TMT_VERSION)", '\''${DESC}'\''); print "\n";' >> $(TRAIN_TABLE_DIR)/history
	echo $(ID_TRAIN_TABLE) > $(TRAIN_TABLE_ANALYSED_DIR)/last_id

############################# MODEL ########################################

model :
	@make model_data_set DATA_SET=train

model_data_set : $(MODEL_DIR)/$(ID_TRAIN_TABLE_COMBINED).model
	#-mkdir -p /net/projects/tectomt_shared/data/models/coreference/${LANGUAGE_UPPER}/perceptron/
	#cp data/${LANGUAGE}/model.train.${ANOT}${JOINT_SUFFIX} /net/projects/tectomt_shared/data/models/coreference/${LANGUAGE_UPPER}/perceptron/text.perspron.${ANOT}${JOINT_SUFFIX}
	-mkdir -p ${TMT_ROOT}/share/data/models/coreference/${LANGUAGE_UPPER}/perceptron/
	cp $(MODEL_DIR)/$(ID_TRAIN_TABLE_COMBINED).model ${TMT_ROOT}/share/data/models/coreference/${LANGUAGE_UPPER}/perceptron/text.perspron.${ANOT}

$(MODEL_DIR)/$(ID_TRAIN_TABLE_COMBINED).model : $(TRAIN_TABLE_DIR)/$(ID_TRAIN_TABLE_COMBINED).table
	mkdir -p $(MODEL_DIR)
	zcat $(TRAIN_TABLE_DIR)/$(ID_TRAIN_TABLE_COMBINED).table > $(TMP_DIR)/unzip/$(ID_TRAIN_TABLE_COMBINED).table
	${TMT_ROOT}/tools/reranker/train -loglevel:FINE -normalizer:dummy $(TMP_DIR)/unzip/$(ID_TRAIN_TABLE_COMBINED).table > $(MODEL_DIR)/$(ID_TRAIN_TABLE_COMBINED).model
	perl -e 'print join("\t", "$(ID_TRAIN_TABLE_COMBINED)", "$(DATE)", "ANAPHOR_AS_CANDIDATE=$(ANAPHOR_AS_CANDIDATE)", "$(TMT_VERSION)", '\''${DESC}'\''); print "\n";' >> $(MODEL_DIR)/history


################################ RESOLVE ####################################

ID_RESOLVED_COMBINED=$(ID_ANALYSED).$(ID_TRAIN_TABLE).$(ID_RESOLVED)

resolve_new:
	@make resolve ID_RESOLVED=$(ID_RESOLVED_NEXT)

resolve: $(RESOLVED_DIR)/$(ID_RESOLVED_COMBINED)/list

#-------------------- GOLD -------------------------------
	#Coref::RearrangeLinks retain_cataphora=1 \

$(RESOLVED_GOLD_DIR)/$(ID_RESOLVED_COMBINED)/list : data/${LANGUAGE}/${DATA_SET}.${DATA_SOURCE}.gold.list
	mkdir -p $(RESOLVED_GOLD_DIR)/$(ID_RESOLVED_COMBINED)
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} \
	${READ_GOLD_DATA_BLOCK} \
	Util::Eval language=${LANGUAGE} zone='$$zone->set_selector("src");' \
	Util::SetGlobal selector=src \
	${PREPROC_BLOCKS} \
	T2T::CopyTtree source_selector=src selector=ref \
	Coref::RemoveLinks type=text selector=src \
	A2T::${LANGUAGE_UPPER}::MarkClauseHeads \
	T2T::SetClauseNumber \
	A2T::SetDocOrds \
	${IS_REFER_BLOCK} \
	A2T::${LANGUAGE_UPPER}::MarkTextPronCoref anaphor_as_candidate=${ANAPHOR_AS_CANDIDATE} \
		model_path=data/models/coreference/${LANGUAGE_UPPER}/perceptron/text.perspron.${ANOT} \
	Write::Treex clobber=1 storable=1 path=$(RESOLVED_GOLD_DIR)/$(ID_RESOLVED_COMBINED)
	find $(RESOLVED_GOLD_DIR)/$(ID_RESOLVED_COMBINED) -name "*.streex" | sort > $(RESOLVED_GOLD_DIR)/$(ID_RESOLVED_COMBINED)/list
	perl -e 'print join("\t", "$(ID_RESOLVED_COMBINED)", "$(DATE)", "ANAPHOR_AS_CANDIDATE=$(ANAPHOR_AS_CANDIDATE)", "$(TMT_VERSION)", '\''${DESC}'\''); print "\n";' >> $(RESOLVED_GOLD_DIR)/history
	echo $(ID_RESOLVED) > $(RESOLVED_GOLD_DIR)/last_id

#-------------------- ANALYSED -------------------------------
	#Coref::RearrangeLinks retain_cataphora=1 \
	#Util::Eval tnode=`cat scripts/copy_grams` selector=ref \

		#model_path=data/models/coreference/${LANGUAGE_UPPER}/perceptron/text.perspron.${ANOT} \

ifdef MODEL_PATH
MODEL_FLAG=model_path=$(MODEL_PATH)
endif

$(RESOLVED_ANALYSED_DIR)/$(ID_RESOLVED_COMBINED)/list : $(ANALYSED_DIR)/$(ID_ANALYSED)/list
	echo $(RESOLVED_DIR)/$(ID_RESOLVED_COMBINED)/list
	mkdir -p $(RESOLVED_ANALYSED_DIR)/$(ID_RESOLVED_COMBINED)
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} -Ssrc \
	Read::Treex from=@$(ANALYSED_DIR)/$(ID_ANALYSED)/list \
	scenarios/$(CLEAN_DATA_SOURCE).$(LANGUAGE).before_data_table.scen \
	A2T::${LANGUAGE_UPPER}::MarkTextPronCoref $(MODEL_FLAG) anaphor_as_candidate=${ANAPHOR_AS_CANDIDATE} diagnostics=1 \
	Write::Treex clobber=1 storable=1 path=$(RESOLVED_ANALYSED_DIR)/$(ID_RESOLVED_COMBINED)
	find $(RESOLVED_ANALYSED_DIR)/$(ID_RESOLVED_COMBINED) -name "*.streex" | sed 's/^.*\///' | sort > $(RESOLVED_ANALYSED_DIR)/$(ID_RESOLVED_COMBINED)/list
	perl -e 'print join("\t", "$(ID_RESOLVED_COMBINED)", "$(DATE)", "ANAPHOR_AS_CANDIDATE=$(ANAPHOR_AS_CANDIDATE)", "$(TMT_VERSION)", '\''${DESC}'\''); print "\n";' >> $(RESOLVED_ANALYSED_DIR)/history
	echo $(ID_RESOLVED) > $(RESOLVED_ANALYSED_DIR)/last_id

################################ EVALUATE ###################################

eval : $(RESOLVED_DIR)/$(ID_RESOLVED_COMBINED)/list
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} -Ssrc \
	Read::Treex from=@$(RESOLVED_DIR)/$(ID_RESOLVED_COMBINED)/list \
	Eval::Coref just_counts=1 type=text anaphor_type=pron selector=ref > data/${LANGUAGE}/results.${DATA_SET}
	perl -e 'print join("\t", "$(DATA_SOURCE).$(ANOT).$(ID_RESOLVED_COMBINED)", "$(DATE)", "${TMT_VERSION}", "DATA_SET=${DATA_SET}", "ANAPHOR_AS_CANDIDATE=${ANAPHOR_AS_CANDIDATE}", '\''${DESC}'\''); print "\n";' >> $(LANGUAGE)_text.coref.results
	./eval.pl < data/${LANGUAGE}/results.${DATA_SET} | sed 's/^/\t/' >> $(LANGUAGE)_text.coref.results
	rm $(DATA_DIR)/results.${DATA_SET}
	tail $(LANGUAGE)_text.coref.results

############################## USING ML FRAMEWORK ###########################

#TRAIN_DATA=/home/mnovak/projects/czeng_coref/data/en/train_00-18.pcedt_bi.en.analysed.ali-mgiza.table
#TRAIN_DATA=/home/mnovak/projects/czeng_coref/data/en/train_00-18.pcedt_bi.en.analysed.ali-sup.table
TRAIN_DATA=/home/mnovak/projects/czeng_coref/data/en/train_00-18.pcedt_bi.en.analysed.nonshared.table
#DEV_DATA=/home/mnovak/projects/czeng_coref/data/en/dev.pcedt_bi.en.analysed.ali-mgiza.table
#DEV_DATA=/home/mnovak/projects/czeng_coref/data/en/dev.pcedt_bi.en.analysed.ali-sup.table
DEV_DATA=/home/mnovak/projects/czeng_coref/data/en/dev.pcedt_bi.en.analysed.nonshared.table
#EVAL_DATA=/home/mnovak/projects/czeng_coref/data/en/eval.pcedt_bi.en.analysed.ali-mgiza.table
#EVAL_DATA=/home/mnovak/projects/czeng_coref/data/en/eval.pcedt_bi.en.analysed.ali-sup.table
EVAL_DATA=/home/mnovak/projects/czeng_coref/data/en/eval.pcedt_bi.en.analysed.nonshared.table

DATA_LIST=TRAIN_DATA DEV_DATA EVAL_DATA
TEST_DATA_LIST=$(DATA_LIST)

train_test :
	$(ML_FRAMEWORK_DIR)/run.sh -f conf/params.ini \
        EXPERIMENT_TYPE=train_test \
        DATA_LIST="$(DATA_LIST)" \
		TEST_DATA_LIST="$(TEST_DATA_LIST)" \
        TRAIN_DATA=$(TRAIN_DATA) \
        DEV_DATA=$(DEV_DATA) \
        EVAL_DATA=$(EVAL_DATA) \
        FEATSET_LIST=conf/$(LANGUAGE).featset_list \
        ML_METHOD_LIST=conf/ml_method.list \
        LRC=$(LRC) \
        TMP_DIR=tmp/ml \
        D="$(D)"

learning_curve :
	$(ML_FRAMEWORK_DIR)/run.sh -f conf/params.ini \
		EXPERIMENT_TYPE=learning_curve \
		DATA_LIST="TRAIN_DATA DEV_DATA" \
		TEST_DATA_LIST="TRAIN_DATA DEV_DATA" \
		TRAIN_DATA=$(TRAIN_DATA) \
		DEV_DATA=$(DEV_DATA) \
		FEATSET_LIST=conf/$(LANGUAGE).featset_list \
		ML_METHOD_LIST=conf/ml_method.list \
		TRAIN_SAMPLE_SIZES="2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384" \
		LRC=$(LRC) \
		TMP_DIR=tmp/ml \
		D="$(D)"


#############################################################################

sort_coref_chains:
	treex -Lcs -Ssrc \
	Read::PDT from=@data/cs/one.data.list schema_dir=/net/work/people/mnovak/schemas \
	A2T::SetDocOrds \
	Coref::RearrangeLinks retain_cataphora=1 \
	Write::Treex to=sorted_chains.treex

suggest_breaks:
	treex -Lcs -Ssrc \
	Read::PDT from=@data/cs/one.data.list schema_dir=/net/work/people/mnovak/schemas \
	Segment::SuggestSegmentBreaks dry_run=1 max_size=3 \
	Write::Treex to=with_breaks.treex

eval_gram: 
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} -Ssrc \
	Read::PDT from=@data/${LANGUAGE}/${DATA_SET}.data.list schema_dir=/net/work/people/mnovak/schemas \
	T2T::CopyTtree source_selector=src selector=ref \
	Coref::RemoveLinks type=gram selector=src \
	A2T::${LANGUAGE_UPPER}::SetFormeme \
	A2T::${LANGUAGE_UPPER}::MarkClauseHeads \
	A2T::${LANGUAGE_UPPER}::MarkReflpronCoref \
	A2T::${LANGUAGE_UPPER}::MarkRelClauseCoref \
	Eval::Coref just_counts=1 type=gram anaphor_type=rel selector=ref > data/${LANGUAGE}/results.rel.${DATA_SET}
	./eval.pl < data/${LANGUAGE}/results.rel.${DATA_SET}

#treex -p --jobs 50 -Lcs -Ssrc 
	#A2T::EN::FindTextCoref 

print_coref_data_one: 
	treex -Lcs \
	Read::PDT from=@data/cs/one.data.list schema_dir=/net/work/people/mnovak/schemas \
	A2T::CS::MarkClauseHeads \
	A2T::SetDocOrds \
	T2T::SetClauseNumber \
	Print::CS::TextPronCorefData > data/cs/one.data

remove_gold_coref_data: 
	rm data/${LANGUAGE}/train.gold


data/train.data.linh : data/train.data.list
	jtred -l data/train.data.list -jb -I linh/Print_coref_features_perc.btred > data/train.data.linh

data/train.data.anaph : data/train.data
	./anaphor_on_line.pl -n < data/train.data > data/train.data.anaph
data/train.data.linh.anaph : data/train.data.linh
	./anaphor_on_line.pl -n < data/train.data.linh > data/train.data.linh.anaph

data/train.data.anaph.sorted : data/train.data.anaph
	sort < data/train.data.anaph > data/train.data.anaph.sorted
data/train.data.linh.anaph.sorted : data/train.data.linh.anaph
	sort < data/train.data.linh.anaph > data/train.data.linh.anaph.sorted

stats/feat_comparison.linh.treex : data/train.data.anaph.sorted data/train.data.linh.anaph.sorted
	./compare_data_files.pl data/train.data.anaph.sorted data/train.data.linh.anaph.sorted > stats/feat_comparison.linh.treex

compare_feat : stats/feat_comparison.linh.treex

#linh/Extract_perceptron_weights_sorted.pm : data/train.data
#${TMT_ROOT}/tools/reranker/train -loglevel:FINE -normalizer:dummy data/train.data | 

linh/Extract_perceptron_weights_sorted.pm : data/train.data.linh
	${TMT_ROOT}/tools/reranker/train -loglevel:FINE -normalizer:dummy data/train.data.linh | \
	zcat | linh/perceptron2perl-sorted.pl > linh/Extract_perceptron_weights_sorted.pm

test_linh : linh/Extract_perceptron_weights_sorted.pm
	#btred -l data/sample.data.list -I linh/Test_coref_features_perc-sorted.btred > data/results.linh.sample
	jtred -l data/dev.data.list -jb -I linh/Test_coref_features_perc-sorted.btred > data/results.linh.dev
	./eval.pl < data/results.linh.dev

#update_model : data/cs/model.train.analysed
#	cp data/cs/model.train /net/projects/tectomt_shared/data/models/coreference/CS/perceptron/text.perspron.gold
#	cp data/cs/model.train ${TMT_ROOT}/share/data/models/coreference/CS/perceptron/text.perspron.gold

	#A2A::CopyAtree source_language=cs source_selector=ref flatten=1 align=1 
	
	#Util::Eval tnode=`cat copy_grams` selector=ref
	#Write::Treex stem_suffix=coref \


