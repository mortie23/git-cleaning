for n in {1..20}; do
  truncate -s 5K file$n.txt
done
## this is a big file that is not very compressable
wget https://chromedriver.storage.googleapis.com/93.0.4577.15/chromedriver_mac64.zip
