DATA_SET = sample
FEAT_ORIGIN = gener
#FEAT_ORIGIN = gold
#DATA_SET = dev

LANGUAGE=cs
LANGUAGE_UPPER=`echo ${LANGUAGE} | tr 'a-z' 'A-Z'`

ifneq (${DATA_SET}, sample)
CLUSTER_FLAGS = -p --qsub '-l mem_free=2G -l act_mem_free=2G' --jobs 50
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
	treex -Lcs -Ssrc \
	Read::PDT from=@data/sample.data.list schema_dir=/net/work/people/mnovak/schemas \
	T2T::CopyTtree source_selector=src selector=ref \
	A2T::StripCoref type=gram selector=src \
	A2T::CS::SetFormeme \
	A2T::CS::MarkClauseHeads \
	A2T::CS::MarkReflpronCoref \
	A2T::CS::MarkRelClauseCoref \
	Eval::Coref type=gram selector=ref

#treex -p --jobs 50 -Lcs -Ssrc 
eval_text: 
	treex ${CLUSTER_FLAGS} -L${LANGUAGE} -Ssrc \
	Read::PDT from=@data/${LANGUAGE}/${DATA_SET}.data.list schema_dir=/net/work/people/mnovak/schemas \
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

print_coref_data: data/${LANGUAGE}/train.data
	
	#treex -L${LANGUAGE}

data/${LANGUAGE}/train.data : data/${LANGUAGE}/train.data.list
	treex -p --jobs 50 -L${LANGUAGE} \
	Read::PDT from=@data/${LANGUAGE}/train.data.list schema_dir=/net/work/people/mnovak/schemas \
	A2T::${LANGUAGE_UPPER}::MarkClauseHeads \
	A2T::SetDocOrds \
	T2T::SetClauseNumber \
	Print::${LANGUAGE_UPPER}::TextPronCorefData > data/cs/train.data

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

data/${LANGUAGE}/model.train : data/${LANGUAGE}/train.data
	${TMT_ROOT}/tools/reranker/train -loglevel:FINE -normalizer:dummy data/${LANGUAGE}/train.data | zcat > data/${LANGUAGE}/model.train

update_model : data/${LANGUAGE}/model.train
	mkdir -p /net/projects/tectomt_shared/data/models/coreference/${LANGUAGE_UPPER}/perceptron/
	cp data/${LANGUAGE}/model.train /net/projects/tectomt_shared/data/models/coreference/${LANGUAGE_UPPER}/perceptron/text.perspron.gold
	mkdir ${TMT_ROOT}/share/data/models/coreference/${LANGUAGE_UPPER}/perceptron/
	cp data/${LANGUAGE}/model.train ${TMT_ROOT}/share/data/models/coreference/${LANGUAGE_UPPER}/perceptron/text.perspron.gold

data/cs/model.train.analysed : data/cs/train.analysed.list
	${TMT_ROOT}/tools/reranker/train -loglevel:FINE -normalizer:dummy data/cs/train.data | zcat > data/cs/model.train

#update_model : data/cs/model.train.analysed
#	cp data/cs/model.train /net/projects/tectomt_shared/data/models/coreference/CS/perceptron/text.perspron.gold
#	cp data/cs/model.train ${TMT_ROOT}/share/data/models/coreference/CS/perceptron/text.perspron.gold

	#A2A::CopyAtree source_language=cs source_selector=ref flatten=1 align=1 
prepare_auto_data : data/cs/${DATA_SET}.analysed.list

data/cs/${DATA_SET}.analysed.list : data/cs/${DATA_SET}.data.list
	treex ${CLUSTER_FLAGS} -Lcs -Sref \
	Read::PDT from=@data/cs/${DATA_SET}.data.list schema_dir=/net/work/people/mnovak/schemas \
	A2W::Detokenize \
	Util::SetGlobal language=cs selector=src \
	W2W::CopySentence source_language=cs source_selector=ref \
	analysis.scen \
	Util::SetGlobal language=cs selector=ref \
	Align::A::MonolingualGreedy to_language=cs to_selector=src \
	Align::T::CopyAlignmentFromAlayer to_language=cs to_selector=src \
	Write::Treex path=data/cs/analysed/${DATA_SET}
	ls data/cs/analysed/${DATA_SET}/*.treex.gz > data/cs/${DATA_SET}.analysed.list

eval_text_gener : data/cs/${DATA_SET}.analysed.list
	treex ${CLUSTER_FLAGS} -Lcs -Ssrc \
	Read::Treex from=@data/cs/${DATA_SET}.analysed.list \
	A2T::CS::MarkTextPronCoref \
	A2T::RearrangeCorefLinks retain_cataphora=1 \
	Eval::Coref just_counts=1 type=text anaphor_type=pron selector=ref > data/cs/results.${DATA_SET}
	./eval.pl < data/cs/results.${DATA_SET}
