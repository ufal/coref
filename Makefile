DATA_SET = sample
DATA_ID = pdt
#DATA_ID = pdt_bridging
ANOT = analysed
#ANOT = gold
#DATA_SET = dev

LANGUAGE=cs
LANGUAGE_UPPER=`echo ${LANGUAGE} | tr 'a-z' 'A-Z'`

JOBS_NUM = 50

ifeq (${DATA_SET}, train)
JOBS_NUM = 200
endif

ifeq (${LANGUAGE}, en)
PREPROC_BLOCKS = W2A::EN::SetAfunAuxCPCoord W2A::EN::SetAfun A2T::EN::SetGrammatemes
endif

ifneq (${DATA_SET}, sample)
CLUSTER_FLAGS = -p --qsub '-hard -l mem_free=6G -l act_mem_free=6G -l h_vmem=6G' --jobs ${JOBS_NUM}
endif

sort_coref_chains:
	treex -Lcs -Ssrc \
	Read::PDT from=@data/cs/one.data.list schema_dir=/net/work/people/mnovak/schemas \
	A2T::SetDocOrds \
	A2T::RearrangeCorefLinks retain_cataphora=1 \
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
	A2T::StripCoref type=gram selector=src \
	A2T::${LANGUAGE_UPPER}::SetFormeme \
	A2T::${LANGUAGE_UPPER}::MarkClauseHeads \
	A2T::${LANGUAGE_UPPER}::MarkReflpronCoref \
	A2T::${LANGUAGE_UPPER}::MarkRelClauseCoref \
	Eval::Coref just_counts=1 type=gram anaphor_type=rel selector=ref > data/${LANGUAGE}/results.rel.${DATA_SET}
	./eval.pl < data/${LANGUAGE}/results.rel.${DATA_SET}

#treex -p --jobs 50 -Lcs -Ssrc 
	#A2T::EN::FindTextCoref 
eval_text: 
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} -Ssrc \
	Read::PDT from=@data/${LANGUAGE}/${DATA_SET}.data.list schema_dir=/net/work/people/mnovak/schemas \
	${PREPROC_BLOCKS} \
	T2T::CopyTtree source_selector=src selector=ref \
	A2T::StripCoref type=text selector=src \
	A2T::${LANGUAGE_UPPER}::MarkClauseHeads \
	T2T::SetClauseNumber \
	A2T::SetDocOrds \
	A2T::${LANGUAGE_UPPER}::MarkTextPronCoref \
	Eval::Coref just_counts=1 type=text anaphor_type=pron selector=ref > data/${LANGUAGE}/results.${DATA_SET}
	./eval.pl < data/${LANGUAGE}/results.${DATA_SET}

print_coref_data_one: 
	treex -Lcs \
	Read::PDT from=@data/cs/one.data.list schema_dir=/net/work/people/mnovak/schemas \
	A2T::CS::MarkClauseHeads \
	A2T::SetDocOrds \
	T2T::SetClauseNumber \
	Print::CS::TextPronCorefData > data/cs/one.data

remove_gold_coref_data: 
	rm data/${LANGUAGE}/train.gold
print_gold_coref_data: data/${LANGUAGE}/train.gold

data/${LANGUAGE}/train.gold : data/${LANGUAGE}/train.data.list
	treex -p --jobs 50 -L${LANGUAGE} \
	Read::PDT from=@data/${LANGUAGE}/train.data.list schema_dir=/net/work/people/mnovak/schemas \
	${PREPROC_BLOCKS} \
	A2T::${LANGUAGE_UPPER}::MarkClauseHeads \
	A2T::SetDocOrds \
	T2T::SetClauseNumber \
	Print::${LANGUAGE_UPPER}::TextPronCorefData > data/${LANGUAGE}/train.gold

print_system_coref_data: data/${LANGUAGE}/train.analysed

#Util::Eval tnode=`cat copy_grams` selector=ref  

data/${LANGUAGE}/train.analysed : data/${LANGUAGE}/train.pdt.analysed.list
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} \
	Read::Treex from=@data/${LANGUAGE}/train.pdt.analysed.list \
	T2T::CopyCorefFromAlignment type=text selector=ref \
	Print::${LANGUAGE_UPPER}::TextPronCorefData selector=src > data/${LANGUAGE}/train.analysed

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

data/${LANGUAGE}/model.train.${ANOT} : data/${LANGUAGE}/train.${ANOT}
	${TMT_ROOT}/tools/reranker/train -loglevel:FINE -normalizer:dummy data/${LANGUAGE}/train.${ANOT} | zcat > data/${LANGUAGE}/model.train.${ANOT}

update_model : data/${LANGUAGE}/model.train.${ANOT}
	#-mkdir -p /net/projects/tectomt_shared/data/models/coreference/${LANGUAGE_UPPER}/perceptron/
	#cp data/${LANGUAGE}/model.train.${ANOT} /net/projects/tectomt_shared/data/models/coreference/${LANGUAGE_UPPER}/perceptron/text.perspron.${ANOT}
	-mkdir -p ${TMT_ROOT}/share/data/models/coreference/${LANGUAGE_UPPER}/perceptron/
	cp data/${LANGUAGE}/model.train.${ANOT} ${TMT_ROOT}/share/data/models/coreference/${LANGUAGE_UPPER}/perceptron/text.perspron.${ANOT}

#update_model : data/cs/model.train.analysed
#	cp data/cs/model.train /net/projects/tectomt_shared/data/models/coreference/CS/perceptron/text.perspron.gold
#	cp data/cs/model.train ${TMT_ROOT}/share/data/models/coreference/CS/perceptron/text.perspron.gold

	#A2A::CopyAtree source_language=cs source_selector=ref flatten=1 align=1 
prepare_auto_data : data/${LANGUAGE}/${DATA_SET}.${DATA_ID}.analysed.list

data/${LANGUAGE}/${DATA_SET}.${DATA_ID}.analysed.list : data/${LANGUAGE}/${DATA_SET}.${DATA_ID}.list
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} -Sref \
	Read::PDT from=@data/${LANGUAGE}/${DATA_SET}.${DATA_ID}.list schema_dir=/net/work/people/mnovak/schemas \
	A2W::Detokenize \
	Util::SetGlobal language=${LANGUAGE} selector=src \
	W2W::CopySentence source_language=${LANGUAGE} source_selector=ref \
	analysis.${LANGUAGE}.scen \
	Util::SetGlobal language=${LANGUAGE} selector=ref \
	Align::A::MonolingualGreedy to_language=${LANGUAGE} to_selector=src \
	Align::T::CopyAlignmentFromAlayer to_language=${LANGUAGE} to_selector=src \
	Align::T::AlignGeneratedNodes to_language=${LANGUAGE} to_selector=src \
	Write::Treex clobber=1 path=data/${LANGUAGE}/analysed/${DATA_ID}/${DATA_SET}
	ls data/${LANGUAGE}/analysed/${DATA_ID}/${DATA_SET}/*.treex.gz > data/${LANGUAGE}/${DATA_SET}.${DATA_ID}.analysed.list
	
	#Util::Eval tnode=`cat copy_grams` selector=ref

eval_text_gener : data/${LANGUAGE}/${DATA_SET}.pdt.analysed.list
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} -Ssrc \
	Read::Treex from=@data/${LANGUAGE}/${DATA_SET}.pdt.analysed.list \
	A2T::${LANGUAGE_UPPER}::MarkTextPronCoref model_path=data/models/coreference/${LANGUAGE_UPPER}/perceptron/text.perspron.${ANOT} \
	A2T::RearrangeCorefLinks retain_cataphora=1 \
	Eval::Coref just_counts=1 type=text anaphor_type=pron selector=ref > data/${LANGUAGE}/results.${DATA_SET}
	./eval.pl < data/${LANGUAGE}/results.${DATA_SET}
