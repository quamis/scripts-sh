#!/bin/bash

# @requires
# gs

# inspired by http://www.alfredklomp.com/programming/shrinkpdf, completly rewritten

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)   
	declare $KEY="$VALUE"
done


: ${FILE:=""};
: ${OFILE:="output.pdf"};
: ${TMPDIR:="/tmp/"};
: ${VERBOSE:="0"};	# 0, 1
: ${KEEP:="smallest"};
#: ${METHODS:="shrink_images_to_150dpi,shrink_images_to_300dpi,shrink_ps2pdf_printer,shrink_ps2pdf_ebook,shrink_convert_zip_150,shrink_convert_zip_300_ps2pdf_printer,shrink_pdftk"};
: ${METHODS:="shrink_images_to_300dpi,shrink_ps2pdf_printer"};


shrink_images_with_gs () {
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
	  -dColorImageDownsampleType=/Bicubic			\
	  -dColorImageResolution=$IMAGE_RESOLUTION		\
	  -dGrayImageDownsampleType=/Bicubic			\
	  -dGrayImageResolution=$IMAGE_RESOLUTION		\
	  -dMonoImageDownsampleType=/Subsample			\
	  -dMonoImageResolution=$IMAGE_RESOLUTION		\
	  -sOutputFile="$OUTPUT"							\
	  "$INPUT"
}


shrink_images_to_150dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	shrink_images_with_gs "$INPUT" "$OUTPUT" "150"
}

shrink_images_to_300dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	shrink_images_with_gs "$INPUT" "$OUTPUT" "300"
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

shrink_convert_zip_300_ps2pdf_printer () {
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



if [[ "$FILE" == "" ]]; then
   echo "Please specify FILE=filename";
   exit;
fi

METHODS_ARR=(${METHODS//,/ })
FILES_ARR=()
for M in "${METHODS_ARR[@]}"; do
	TMPFILE=`mktemp --tmpdir="${TMPDIR}"`;

	if [ "$VERBOSE" = "1" ]; then
		printf '%-*s: ' 25 "$M"
	fi;
	
	$M "$FILE" "$TMPFILE";

	if [ "$VERBOSE" = "1" ]; then
		du -sh "$TMPFILE";
	fi;
	FILES_ARR+=("$TMPFILE")
done

FILELIST=`mktemp --tmpdir="${TMPDIR}"`;
for TMPFILE in "${FILES_ARR[@]}"; do
	SIZE=`du --bytes "$TMPFILE" | cut -f1 -d" "`
	echo "$SIZE $TMPFILE" >> "$FILELIST";
done;

SMALLEST_FILE=`cat "$FILELIST" | sort -n | head -n 1 | cut -f2 -d" "`
if [ "$KEEP" == "smallest" ]; then
	# default
	SMALLEST_FILE=`cat "$FILELIST" | sort -n | head -n 1 | cut -f2 -d" "`
elif [ "$KEEP" == "largest" ]; then
	# default
	SMALLEST_FILE=`cat "$FILELIST" | sort -rn | head -n 1 | cut -f2 -d" "`
fi;

cp -f "$SMALLEST_FILE" "$OFILE"

rm "$FILELIST";
for TMPFILE in "${FILES_ARR[@]}"; do
	rm "$TMPFILE";
done;
