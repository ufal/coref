/home/bojar/diplomka/czeng/tmt/applications/czeng10
cat work.filelist | /home/bojar/tools/vimtext/autocat --fl=- | grep '^  <LM' \
| cut -d'"' -f2 | cut -d- -f2 | cut -dS -f1 | uniq -c | sort -n \
| sed 's/^[ \t]*//' | sed 's/ /\t/g' | cut -f1 | uniq -c | sort -nr
popd
