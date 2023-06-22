# dependencies
```sh
apt install gs pdftk qpdf
```

# usage:
```sh
FILE="xyz.pdf";
pdf.autoShrinkOneFile.sh METHODS="lowq" KEEP=smaller RUN_MODE=parallel FILE="$FILE"





# shrinker analysis
pdf.autoShrinkOneFile.sh METHODS="default" KEEP=none RUN_MODE=parallel FILE="$FILE" VERBOSE="2"

for FILE in *.pdf; do
    echo $FILE;
    [[ ! -f "$FILE.log" ]] && pdf.autoShrinkOneFile.sh METHODS="all" KEEP=none RUN_MODE=parallel FILE="$FILE" VERBOSE="2" > "$FILE.log";
done


rm ./report.json;
for FILE in *.log; do
    cat "$FILE" | egrep -o "^(original|(shrink_[a-zA-Z0-9_]+?))\s[0-9]+.+" | generateReport.php;
done;
generateReport.php | less;




# for FILE in *.log; do echo ""; echo "$FILE"; cat "$FILE" | egrep -o "^(original|(shrink_[a-zA-Z0-9_]+?))\s[0-9]+" | sort -n -t$'\t' -k2,2; done > report.txt



```
