#!/bin/bash

# @requires
# apt install ghostscript pdftk qpdf
# setup:https://stackoverflow.com/questions/52998331/imagemagick-security-policy-pdf-blocking-conversion
#	in /etc/ImageMagick-7/policy.xml
#	  <policy domain="coder" rights="read | write" pattern="PDF" />


# pdf.autoShrinkOneFile.sh FILE=tests/input.pdf

# inspired by http://www.alfredklomp.com/programming/shrinkpdf, completly rewritten

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done


: ${FILE:=""};
: ${OFILE:="$FILE-compressed,__SIZE__,v__INDEX__.pdf"};
: ${TMPDIR:="/tmp/"};
: ${VERBOSE:="1"};	# 0, 1
: ${KEEP:="smallest"};

: ${METHODS:="all"};

: ${RUN_MODE:="sequential"};	# 'dry-run', 'parallel', 'sequential'
: ${COMMANDFILE:=`mktemp --tmpdir="${TMPDIR}"`};
: ${THREADS:="`parallel --no-notice --number-of-cores`"};
: ${MAX_LOAD:="95%"};




helper_gs_generalShrink () {
	local INPUT="$1"
	local OUTPUT="$2"
	local PARAMS="$3"

	#@see https://stackoverflow.com/questions/10450120/optimize-pdf-files-with-ghostscript-or-other

	# CMD="gs -o \"$OUTPUT\" -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite $PARAMS -f \"$INPUT\""
	# echo $CMD;
	# eval $CMD

	gs -o "$OUTPUT" -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite $PARAMS -f "$INPUT"
}

helper_gs_shrinkImages () {
	local INPUT="$1"
	local OUTPUT="$2"
	local IMAGE_RESOLUTION="$3"

	#@see https://www.ghostscript.com/doc/9.22/VectorDevices.htm#PDFWRITE
	gs												\
	  -q -dNOPAUSE -dBATCH -dSAFER					\
	  -sDEVICE=pdfwrite								\
	  -dCompatibilityLevel=1.4						\
	  -dPDFSETTINGS=/screen							\
	  -dEmbedAllFonts=true							\
	  -dSubsetFonts=true							\
	  -dAutoRotatePages=/None						\
	  -dDownsampleColorImages=true					\
	  -dDetectDuplicateImages=true					\
	  -dColorImageDownsampleType=/Bicubic			\
	  -dColorImageResolution=$IMAGE_RESOLUTION		\
	  -dGrayImageDownsampleType=/Bicubic			\
	  -dGrayImageResolution=$IMAGE_RESOLUTION		\
	  -dMonoImageDownsampleType=/Subsample			\
	  -dMonoImageResolution=$IMAGE_RESOLUTION		\
	  -sOutputFile="$OUTPUT"						\
	  "$INPUT"
}

helper_qpdf_generalShrink () {
	local INPUT="$1"
	local OUTPUT="$2"
	local PARAMS="$3"

	# in order to make pdftk work on Ubuntu, you need to
	#	apt install qpdf


	qpdf $PARAMS "$INPUT" "$OUTPUT"
}

# -------------------------------------------------------------------------------------------------

shrink_remove_images () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dFILTERIMAGE"
}

shrink_remove_images_remove_vectors () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dFILTERIMAGE -dFILTERVECTOR"
}

shrink_images_to_75dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_shrinkImages "$INPUT" "$OUTPUT" "75"
}

shrink_images_to_150dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_shrinkImages "$INPUT" "$OUTPUT" "150"
}

shrink_images_to_300dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_shrinkImages "$INPUT" "$OUTPUT" "300"
}

shrink_ps2pdf_printer () {
	local INPUT="$1"
	local OUTPUT="$2"

	ps2pdf -dPDFSETTINGS=/printer "$INPUT" "$OUTPUT"
}

shrink_ps2pdf_ebook () {
	local INPUT="$1"
	local OUTPUT="$2"

	ps2pdf -dPDFSETTINGS=/ebook "$INPUT" "$OUTPUT"
}

shrink_convert_zip_150 () {
	local INPUT="$1"
	local OUTPUT="$2"

	# in order to make convert work on Ubuntu, you need to remove the restriction placed on convert for encoding PDF's:
	# comment <!-- <policy domain="coder" rights="none" pattern="PDF" /> --> into /etc/ImageMagick-6/policy.xml
	# @see https://askubuntu.com/questions/1081895/trouble-with-batch-conversion-of-png-to-pdf-using-convert

	convert -compress Zip -density 150x150 "$INPUT" "$OUTPUT"
}

shrink_convert_zip_150_ps2pdf_printer () {
	local INPUT="$1"
	local OUTPUT="$2"

	# in order to make convert work on Ubuntu, you need to remove the restriction placed on convert for encoding PDF's:
	# comment <!-- <policy domain="coder" rights="none" pattern="PDF" /> --> into /etc/ImageMagick-6/policy.xml
	# @see https://askubuntu.com/questions/1081895/trouble-with-batch-conversion-of-png-to-pdf-using-convert

	convert -compress Zip -density 150x150 "$INPUT" "$OUTPUT.tmp.pdf"
	ps2pdf -dPDFSETTINGS=/printer "$OUTPUT.tmp.pdf" "$OUTPUT"
	rm "$OUTPUT.tmp.pdf"
}


shrink_pdftk () {
	local INPUT="$1"
	local OUTPUT="$2"

	# in order to make pdftk work on Ubuntu, you need to
	#	sudo snap install pdftk

	pdftk "$INPUT" output "$OUTPUT" compress
}

shrink_gs_v11 () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook"
}
shrink_gs_v12 () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen"
}
shrink_gs_v15 () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true "
}
shrink_gs_v16 () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true "
}
shrink_gs_v17 () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true -c \"<</AlwaysEmbed [ ]>> setdistillerparams\" -c \"<</NeverEmbed [/Courier /Courier-Bold /Courier-Oblique /Courier-BoldOblique /Helvetica /Helvetica-Bold /Helvetica-Oblique /Helvetica-BoldOblique /Times-Roman /Times-Bold /Times-Italic /Times-BoldItalic /Symbol /ZapfDingbats /Arial]>> setdistillerparams\""
}

shrink_ps2pdf_v11 () {
	local INPUT="$1"
	local OUTPUT="$2"

	local TMPFILE=`mktemp --tmpdir="${TMPDIR}"`;

	pdf2ps "$INPUT" "$TMPFILE"
	ps2pdf -dPDFSETTINGS=/screen "$TMPFILE" "$OUTPUT"
}

shrink_qpdf_v11 () {
	local INPUT="$1"
	local OUTPUT="$2"

	helper_qpdf_generalShrink "$INPUT" "$OUTPUT" "--object-streams=generate --compress-streams=y --recompress-flate --compression-level=9 --optimize-images"
}





if [[ "$FILE" == "" ]]; then
   echo "Please specify FILE=filename";
   exit;
fi

if [[ "$METHODS" == "all" ]]; then
	METHODS=$(compgen -A function | egrep "shrink_" | tr "\n" ",");
elif [[ "$METHODS" == "gs" ]]; then
	METHODS=$(compgen -A function | egrep "(shrink_.*gs_)" | tr "\n" ",");
elif [[ "$METHODS" == "qpdf" ]]; then
	METHODS=$(compgen -A function | egrep "(shrink_.*qpdf_)" | tr "\n" ",");
elif [[ "$METHODS" == "destructive" ]]; then
	METHODS=$(compgen -A function | egrep "(shrink_.*remove_)" | tr "\n" ",");
elif [[ "$METHODS" == "lowq" ]]; then
	METHODS=$(compgen -A function | egrep "(shrink_.*(remove_|images_|qpdf_))" | tr "\n" ",");
elif [[ "$METHODS" == "hiq" ]]; then
	METHODS=$(compgen -A function | egrep "(shrink_gs_|shrink_convert_|shrink_ps2pdf_)|(shrink.*(150|300))" | tr "\n" ",");
fi;
# else, use the list as-is




echo > "$COMMANDFILE";
METHODS_ARR=(${METHODS//,/ })

if [ "$VERBOSE" = "1" ]; then
	echo "Compressing $FILE, `du -h "$FILE" | sed -r "s/\\s+/ /g" | cut -f1 -d" "`";
	echo "  trying ${#METHODS_ARR[@]} methods";
elif [ "$VERBOSE" = "2" ]; then
	echo -e "original\t`du --bytes "$FILE"`";
fi

FILES_ARR=()
for M in "${METHODS_ARR[@]}"; do
	TMPFILE=`mktemp --tmpdir="${TMPDIR}"`;

	if [ "$VERBOSE" = "1" ]; then
		echo "(printf '    %-*s: ' 25 \"$M\" && $M \"$FILE\" \"$TMPFILE\" && du -sh \"$TMPFILE\")" >> "$COMMANDFILE";
	elif [ "$VERBOSE" = "2" ]; then
		echo "(echo -ne \"$M\t\" && $M \"$FILE\" \"$TMPFILE\" && du --bytes \"$TMPFILE\")" >> "$COMMANDFILE";
	else
		echo "($M \"$FILE\" \"$TMPFILE\")" >> "$COMMANDFILE";
	fi;
	FILES_ARR+=("$TMPFILE")
done;

# simply display the "to-run" commands
if [ "$RUN_MODE" = "parallel" ]; then
	# run the list in paralel
	# @see https://www.gnu.org/software/parallel/man.html

	EXPORTED_METHODS=$(compgen -A function | egrep "helper_|shrink_");
	EXPORTED_METHODS_ARR=(${EXPORTED_METHODS//,/ })
	for M in "${EXPORTED_METHODS_ARR[@]}"; do
		export -f "$M";
	done;

	parallel --no-notice --jobs $THREADS --load $MAX_LOAD < "$COMMANDFILE"

elif [ "$RUN_MODE" = "sequential" ]; then
	source "$COMMANDFILE";
elif [ "$RUN_MODE" = "dry-run" ]; then
	cat "$COMMANDFILE";
else
	echo "Unknown run mode";
fi;

FILELIST=`mktemp --tmpdir="${TMPDIR}"`;
for TMPFILE in "${FILES_ARR[@]}"; do
	SIZE=`du --bytes "$TMPFILE" | sed -r "s/\\s+/ /g" | cut -f1 -d" "`
	echo "$SIZE $TMPFILE" >> "$FILELIST";
done;


SMALLEST_FILES=()
if [ "$KEEP" == "smallest" ]; then
	# default
	SMALLEST_FILE=`cat "$FILELIST" | sort -n | head -n 1 | cut -f2 -d" "`
	SMALLEST_FILES+=("$SMALLEST_FILE")
elif [ "$KEEP" == "smaller" ]; then
	FILESIZE=`du --bytes "$FILE" | sed -r "s/\\s+/ /g" | cut -f1 -d" "`;

	FILELIST2=`mktemp --tmpdir="${TMPDIR}"`;
	cat "$FILELIST" | sort -n | awk -F" "  "{ if( \$1<$FILESIZE ) print \$2 }" > "$FILELIST2"

	while read F; do
		SMALLEST_FILES+=("$F")
	done < "$FILELIST2"

	rm "$FILELIST2";
elif [ "$KEEP" == "largest" ]; then
	SMALLEST_FILE=`cat "$FILELIST" | sort -rn | head -n 1 | cut -f2 -d" "`
	SMALLEST_FILES+=("$SMALLEST_FILE")
elif [ "$KEEP" == "none" ]; then
	# do nothing
	SMALLEST_FILES=()
else
	echo "Please specify KEEP";
	exit;
fi;


INDEX=0;
for TMPFILE in "${SMALLEST_FILES[@]}"; do
	NNAME="$OFILE";

	INDEX=$((INDEX + 1));
	NNAME="${NNAME/__INDEX__/$INDEX}";

	SIZE=`du -h "$TMPFILE" | sed -r "s/\\s+/ /g" | cut -f1 -d" "`
	NNAME="${NNAME/__SIZE__/$SIZE}";

	if [ "$VERBOSE" = "1" ]; then
		echo "--> ${NNAME}";
	fi;

	cp -f "$TMPFILE" "${NNAME}";
done;


rm "$FILELIST";
for TMPFILE in "${FILES_ARR[@]}"; do
	rm "$TMPFILE";
done;
