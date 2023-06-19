#!/bin/bash

# @requires
# apt install ghostscript pdftk qpdf


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
# : ${METHODS:="shrink_images_to_75dpi,shrink_images_to_150dpi,shrink_images_to_300dpi,shrink_ps2pdf_printer,shrink_ps2pdf_ebook,shrink_convert_zip_150,shrink_convert_zip_300_ps2pdf_printer,shrink_pdftk,qpdf_recompress_v10"};
: ${METHODS:="shrink_images_to_300dpi,shrink_ps2pdf_printer,qpdf_recompress_v10"};
# : ${METHODS:="shrink_recompress_v10,shrink_recompress_v11,shrink_recompress_v15,shrink_recompress_v16,shrink_recompress_v17,shrink_recompress_v18,shrink_recompress_v30"};

# : ${METHODS:=$((compgen -A function | grep shrink_ | tr "\n" ","))};


local_shrink_images_with_gs () {
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


local_shrink_with_gs () {
	local INPUT="$1"
	local OUTPUT="$2"
	local PARAMS="$3"

	#@see https://stackoverflow.com/questions/10450120/optimize-pdf-files-with-ghostscript-or-other

	CMD="gs -o \"$OUTPUT\" -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite $PARAMS -f \"$INPUT\""
	# echo $CMD;
	eval $CMD
}

shrink_images_to_75dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_images_with_gs "$INPUT" "$OUTPUT" "75"
}

shrink_images_to_150dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_images_with_gs "$INPUT" "$OUTPUT" "150"
}

shrink_images_to_300dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_images_with_gs "$INPUT" "$OUTPUT" "300"
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


local_shrink_images_with_qpdf () {
	local INPUT="$1"
	local OUTPUT="$2"
	local PARAMS="$3"

	# in order to make pdftk work on Ubuntu, you need to
	#	apt install qpdf


	qpdf $PARAMS "$INPUT" "$OUTPUT"

}

qpdf_recompress_v10 () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_images_with_qpdf "$INPUT" "$OUTPUT" "--object-streams=generate --compress-streams=y --recompress-flate --compression-level=9 --optimize-images"
}

shrink_recompress_v10 () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_with_gs "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook"
}
shrink_recompress_v11 () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_with_gs "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen"
}
shrink_recompress_v15 () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_with_gs "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true "
}
shrink_recompress_v16 () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_with_gs "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true "
}
shrink_recompress_v17 () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_with_gs "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true -c \"<</AlwaysEmbed [ ]>> setdistillerparams\" -c \"<</NeverEmbed [/Courier /Courier-Bold /Courier-Oblique /Courier-BoldOblique /Helvetica /Helvetica-Bold /Helvetica-Oblique /Helvetica-BoldOblique /Times-Roman /Times-Bold /Times-Italic /Times-BoldItalic /Symbol /ZapfDingbats /Arial]>> setdistillerparams\""
}
shrink_recompress_v18 () {
	local INPUT="$1"
	local OUTPUT="$2"

	local_shrink_with_gs "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true -c \"<</AlwaysEmbed [ ]>> setdistillerparams\" -c \"<</NeverEmbed [/Courier /Courier-Bold /Courier-Oblique /Courier-BoldOblique /Helvetica /Helvetica-Bold /Helvetica-Oblique /Helvetica-BoldOblique /Times-Roman /Times-Bold /Times-Italic /Times-BoldItalic /Symbol /ZapfDingbats /Arial]>> setdistillerparams\""
}

shrink_recompress_v30 () {
	local INPUT="$1"
	local OUTPUT="$2"

	local TMPFILE=`mktemp --tmpdir="${TMPDIR}"`;

	pdf2ps "$INPUT" "$TMPFILE"
	ps2pdf -dPDFSETTINGS=/screen "$TMPFILE" "$OUTPUT"
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
	# default
	SMALLEST_FILE=`cat "$FILELIST" | sort -rn | head -n 1 | cut -f2 -d" "`
	SMALLEST_FILES+=("$SMALLEST_FILE")
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

	echo "--> ${NNAME}";
	cp -f "$TMPFILE" "${NNAME}";
done;


rm "$FILELIST";
for TMPFILE in "${FILES_ARR[@]}"; do
	rm "$TMPFILE";
done;
