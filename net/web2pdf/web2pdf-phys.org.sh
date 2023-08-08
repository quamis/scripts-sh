#!/bin/bash

# sudo apt install xvfb html-xml-utils wkhtmltopdf



if [ "$1" = "--help" ]; then
    cat <<HELP
    $0 [options]
HELP

	exit 1;
fi;



# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done

: ${LISTFILE:="./urls.txt"};
: ${PAGESIZE:="A6"};
: ${METHODS:="wkhtml2pdf"};
: ${SLEEP:="19"};
: ${TMPDIR:="/tmp/"};
: ${VERBOSE:="0"};	# 0, 1
: ${ODIR:="./pdf/"};
: ${KEEP:="smallest"};

: ${RUN_MODE:="parallel"};	# 'dry-run', 'parallel', 'sequential'
: ${THREADS:="`parallel --no-notice --number-of-cores`"};
: ${MAX_LOAD:="95%"};

# clear the command list
MD5=($( cat "${LISTFILE}" | md5sum ));
COMMANDFILE="${TMPDIR}/tmp.convert-all,${MD5},${PAGESIZE}.sh"

RESUME="0";
if [ -f "$COMMANDFILE" ]; then
	RESUME="1";
fi;

SCRIPT_PATH=`realpath $0`;
SCRIPT_DIR=`dirname $SCRIPT_PATH`;

if [ "$RESUME" == '0' ]; then
    echo > "$COMMANDFILE";
    INDEX=$(( 0 ));
	while IFS="" read -r URL || [ -n "$URL" ]; do
        URL=`echo "$URL" | sed -r "s/^[ \t\r]*//" | sed -r "s/[ \t\r]*\$//"`;
        if [ ! -z "$URL" ]; then
            echo "Processing $URL";

            INDEX=$(( INDEX + 1 ));

            HTML=`wget --quiet -O - "$URL" | hxnormalize -l 1024 -x`
            TITLE=`echo "$HTML" | hxselect -s "\n" -i -c 'title'`
            DATERAW=`echo "$HTML" | hxselect -s "\n" -i -c 'article.news-article .article__info p'`
            DATE=`date -d "$DATERAW" '+%Y-%m-%d'`

            if [ -z "$TITLE" ]; then
                TITLE="RND-$RANDOM"
            fi

            FILE="page-${PAGESIZE}, ${DATE}, ${TITLE}.pdf";
            FILE=`echo $FILE | sed -e "s/:/,/g"`;
            FILE=`echo $FILE | sed -e "s/?//g"`;
            if [ ${#FILE} -ge 124 ]; then
                FILE="${FILE:0:120}...pdf";
            fi;
            echo "    $FILE";
            FILE=`printf "%q" "$FILE"`;

            if [ ! -f "$FILE" ]; then
                CMD=$(cat <<-END
                    [ ! -f "$FILE" ] && sleep $(($INDEX%$SLEEP)) && wkhtmltopdf \
                        --page-size $PAGESIZE \
                        --margin-top "5mm" \
                        --margin-bottom "5mm" \
                        --margin-left "5mm" \
                        --margin-right "5mm" \
                        --enable-javascript \
                        --javascript-delay 10000 \
                        --debug-javascript \
                        --window-status "clean" \
                        --load-error-handling ignore \
                        --run-script 'javascript:(function(d, s) {s = d.createElement("script");s.type ="text/javascript";s.async = true;s.onload = function(){};s.src = "file://${SCRIPT_DIR}/web2pdf-phys.org-simplify.js";d.getElementsByTagName("head")[0].appendChild(s);}(document));'  \
                        "$URL" \
                        $FILE \
                        2>&1 > /dev/null;
END
                    );
                    CMD="`echo $CMD | sed -r 's/^[\s]+/ /g'`";


                    echo "$CMD" >> "$COMMANDFILE";
                else
                    printf '    ...already saved\n'
                fi;
            fi;
	done < "$LISTFILE";
else
	echo "Resuming job from file $COMMANDFILE";
	echo "";
	echo "";
fi;




# process the command list

# simply display the "to-run" commands
if [ "$RUN_MODE" = "parallel" ]; then
	# run the list in paralel
	# @see https://www.gnu.org/software/parallel/man.html
	parallel --no-notice --bar --jobs $THREADS --load $MAX_LOAD < "$COMMANDFILE"
elif [ "$RUN_MODE" = "sequential" ]; then
	bash -x "$COMMANDFILE";
elif [ "$RUN_MODE" = "dry-run" ]; then
	cat "$COMMANDFILE";
else
	# TODO: sequential conversion
	echo "Unknown run mode";
fi;

rm $COMMANDFILE;


