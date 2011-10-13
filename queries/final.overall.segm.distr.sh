zcat /net/data/czeng09-public-release/data-plaintext/*.gz | cut -f1 \
| cut -d- -f2 | uniq -c | sed 's/^[ \t]*//' | sed 's/ /\t/g' | cut -f1 \
| sort | uniq -c | sort -nr
