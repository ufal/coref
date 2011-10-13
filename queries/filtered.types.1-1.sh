zcat ~bojar/diplomka/czeng/devel/completion/czeng.filtered.gz | cut -f1,2,6 | grep -v "ERRoR" \
| perl -ne 'chomp $_; ($type,$mn) = ($_ =~ /^transformed-data\/(.*?)\/.*\t(.*)$/); print "$type\t$mn\n";' \
| grep "1-1$" | cut -f1 | sort | uniq -c | sort -nr
