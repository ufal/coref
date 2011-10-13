zcat /net/data/czeng09-public-release/data-plaintext/*.gz | cut -f1 \
| cut -d- -f1,2 | sed 's/-/\t/' | uniq -c | sed 's/^[ \t]*//' \
| sed 's/ /\t/g' | cut -f1,2 | sort -k2,2 | uniq -c | sort -nr -k1,1 \
| sort -b -s -k3,3
