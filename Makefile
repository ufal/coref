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

eval_text: 
	#treex -Lcs -Ssrc
	treex -p --jobs 50 -Lcs -Ssrc \
	Read::PDT from=@data/dev.data.list schema_dir=/net/work/people/mnovak/schemas \
	T2T::CopyTtree source_selector=src selector=ref \
	A2T::StripCoref type=text selector=src \
	A2T::CS::MarkClauseHeads \
	T2T::SetClauseNumber \
	A2T::CS::MarkTextPronCoref \
	Eval::Coref just_counts=1 type=text selector=ref > data/results.dev
	./eval.pl < data/results.dev

print_coref_data_one: 
	treex -Lcs \
	Read::PDT from=@data/one.data.list schema_dir=/net/work/people/mnovak/schemas \
	A2T::CS::MarkClauseHeads \
	T2T::SetClauseNumber \
	Print::TextPronCorefData > data/one.data

print_coref_data: data/train.data
data/train.data : data/train.data.list
	treex -p --jobs 50 -Lcs \
	Read::PDT from=@data/train.data.list schema_dir=/net/work/people/mnovak/schemas \
	A2T::CS::MarkClauseHeads \
	T2T::SetClauseNumber \
	Print::TextPronCorefData > data/train.data

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

data/model.train : data/train.data
	${TMT_ROOT}/tools/reranker/train -loglevel:FINE -normalizer:dummy data/train.data | zcat > data/model.train

update_model : data/model.train
	cp data/model.train /net/projects/tectomt_shared/data/models/coreference/CS/perceptron/text.perspron.gold
	rm ${TMT_ROOT}/share/data/models/coreference/CS/perceptron/text.perspron.gold
