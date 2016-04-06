#!/bin/bash

#data_list=data/en/analysed/pcedt_bi/dev/0003/list
data_list=$1
category=$2

coref_scorer=/net/work/people/mnovak/tools/x86_64/coref_scorer/v8.01/scorer.pl

tmp_dir=tmp/coref_eval/`date +%Y-%m-%d_%H-%M-%S`_$$
mkdir -p $tmp_dir

if [ ! -z "$category" ]; then
    specialized_block="Coref::PrepareSpecializedEval category=\"$category\""
fi

# extract key and response links
mkdir -p $tmp_dir/key
mkdir -p $tmp_dir/response
#-p --jobs 100
treex -p --jobs 100 --priority 0 -Lcs -Sref \
    Read::Treex from=@$data_list \
    A2T::SetDocOrds \
    $specialized_block \
    Coref::MarkMentionsForScorer layer=t \
    Write::SemEval2010 layer=t path="$tmp_dir/key" \
    Coref::RemoveLinks \
    T2T::CopyCorefFromAlignment selector=src \
    Coref::MarkMentionsForScorer layer=t \
    Write::SemEval2010 layer=t path="$tmp_dir/response"
find $tmp_dir/key -name '*.conll' | sort | xargs cat > $tmp_dir/coref.key.txt
find $tmp_dir/response -name '*.conll' | sort | xargs cat > $tmp_dir/coref.response.txt

echo "Running the scorer..." >&2
$coref_scorer all $tmp_dir/coref.key.txt $tmp_dir/coref.response.txt none > $tmp_dir/coref.score.txt
cat $tmp_dir/coref.score.txt
    
#    Util::SetGlobal selector=src
#    Coref::RemoveLinks type=text
#    My::RemoveCoreferenceLoops
#    A2T::CS::MarkTextPronCoref anaphor_as_candidate=1

#    Write::SemEval2010 layer=t to="." substitute="{^.*/(.*)}{$tmp_dir/key/\$1.txt}" \
#    Write::SemEval2010 layer=t to="." substitute="{^.*/(.*)}{$tmp_dir/response/\$1.txt}"
