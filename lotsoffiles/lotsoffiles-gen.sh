for n in {1..20}; do
  truncate -s 5K file$n.txt
done
truncate -s 10M file-big.txt
