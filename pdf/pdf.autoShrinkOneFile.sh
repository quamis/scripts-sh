#!/bin/bash

# @requires
# apt install ghostscript pdftk qpdf
# setup:https://stackoverflow.com/questions/52998331/imagemagick-security-policy-pdf-blocking-conversion
#	in /etc/ImageMagick-7/policy.xml
#	  <policy domain="coder" rights="read | write" pattern="PDF" />


# pdf.autoShrinkOneFile.sh FILE=tests/input.pdf


if [ "$1" = "--help" ]; then
    cat <<HELP
    $0 [options]
	FILE=./input.pdf
	OFILE="\$FILE-compressed,__SIZE__,__INDEX__,__METHOD__.pdf"
	VERBOSE=1,0
	KEEP=smallest,largest,smaller,none,all
	METHODS=default,hiq,lowq,all,gs,destructive
	RUN_MODE=parallel,sequential,dry-run
HELP

	exit 1;
fi;


# inspired by http://www.alfredklomp.com/programming/shrinkpdf, completly rewritten

# THIS ALLOWS INJECTING VARS into the local namespace
# might not be very secure, be careful how you declare & check variables
for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2- -d=)
	declare $KEY="$VALUE"
done


: ${FILE:=""};
# : ${OFILE:="$FILE-compressed,__SIZE__,v__INDEX__.pdf"};
: ${OFILE:="$FILE-compressed,__SIZE__,__METHOD__.pdf"};
: ${TMPDIR:="/tmp/"};
: ${VERBOSE:="1"};	# 0, 1
: ${KEEP:="smallest"};

: ${METHODS:="default"};

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

helper_gs_shrinkImages_screen () {
	local INPUT="$1"
	local OUTPUT="$2"
	local IMAGE_RESOLUTION="$3"

	#@see https://www.ghostscript.com/doc/9.22/VectorDevices.htm#PDFWRITE
	# @see https://web.mit.edu/ghostscript/www/Ps2pdf.htm#Options
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
	  -r$IMAGE_RESOLUTION							\
	  -dColorImageDownsampleType=/Bicubic			\
	  -dColorImageResolution=$IMAGE_RESOLUTION		\
	  -dGrayImageDownsampleType=/Bicubic			\
	  -dGrayImageResolution=$IMAGE_RESOLUTION		\
	  -dMonoImageDownsampleType=/Subsample			\
	  -dMonoImageResolution=$IMAGE_RESOLUTION		\
	  -sOutputFile="$OUTPUT"						\
	  -c "<</ColorImageDict  <</QFactor 0.24 /Blend 1 /ColorTransform 1 /HSample [1 1 1 1] /VSample [1 1 1 1]>> >> setdistillerparams <</GrayImageDict  <</QFactor 0.24 /Blend 1 /ColorTransform 1 /HSample [1 1 1 1] /VSample [1 1 1 1]>> >> setdistillerparams" \
	  -f "$INPUT"
}


helper_gs_shrinkImages_printer () {
	local INPUT="$1"
	local OUTPUT="$2"
	local IMAGE_RESOLUTION="$3"

# @see https://stackoverflow.com/questions/72950690/gs-ghost-script-cannot-adjust-pdf-size-either-adjust-to-28mb-or-either-to-128
# cmdline=
# -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="output.pdf" -dAutoRotatePages=/None \
# -dEmbedAllFonts=true -dSubsetFonts=true -dDetectDuplicateImages=true -dDoThumbnails=false \
# -dAutoFilterColorImages=false -dAutoFilterGrayImages=false -dAutoFilterMonoImages=false \
# -r144 -dColorImageResolution=144 -dGrayImageResolution=144 -dMonoImageResolution=144 \
# -dDownsampleColorImages=true -dColorImageDownsampleType=/Bicubic -dColorImageDownsampleThreshold=1.0 \
# -dDownsampleGrayImages=true -dGrayImageDownsampleType=/Bicubic -dGrayImageDownsampleThreshold=1.0 \
# -dDownsampleMonoImages=true -dMonoImageDownsampleType=/Subsample -dMonoImageDownsampleThreshold=1.0 \
# -dColorConversionStrategy=/sRGB -dProcessColorModel=/DeviceRGB -dPassThroughJPEGImages=false \
# -dColorImageFilter=/DCTEncode -dGrayImageFilter=/DCTEncode -dMonoImageFilter=/CCITTFaxEncode \
# -c " <</ColorImageDict  <</QFactor 0.24 /Blend 1 /ColorTransform 1 /HSample [1 1 1 1] /VSample [1 1 1 1]>> >> setdistillerparams <</GrayImageDict  <</QFactor 0.24 /Blend 1 /ColorTransform 1 /HSample [1 1 1 1] /VSample [1 1 1 1]>> >> setdistillerparams" \
# -f "input.pdf"


	# @see https://www.ghostscript.com/doc/9.22/VectorDevices.htm#PDFWRITE
	# @see https://web.mit.edu/ghostscript/www/Ps2pdf.htm#Options
	# @see https://ghostscript.com/docs/9.54.0/VectorDevices.htm
	gs												\
	  -q -dNOPAUSE -dBATCH -dSAFER					\
	  -sDEVICE=pdfwrite								\
	  -dCompatibilityLevel=1.4						\
	  -dPDFSETTINGS=/printer						\
	  -dEmbedAllFonts=true							\
	  -dSubsetFonts=true							\
	  -dAutoRotatePages=/None						\
	  -dDownsampleColorImages=true					\
	  -dDetectDuplicateImages=true					\
	  -r$IMAGE_RESOLUTION							\
	  -dColorImageDownsampleType=/Bicubic			\
	  -dColorImageResolution=$IMAGE_RESOLUTION		\
	  -dGrayImageDownsampleType=/Bicubic			\
	  -dGrayImageResolution=$IMAGE_RESOLUTION		\
	  -dMonoImageDownsampleType=/Subsample			\
	  -dMonoImageResolution=$IMAGE_RESOLUTION		\
	  -sOutputFile="$OUTPUT"						\
	  -c "<</ColorImageDict  <</QFactor 0.24 /Blend 1 /ColorTransform 1 /HSample [1 1 1 1] /VSample [1 1 1 1]>> >> setdistillerparams <</GrayImageDict  <</QFactor 0.24 /Blend 1 /ColorTransform 1 /HSample [1 1 1 1] /VSample [1 1 1 1]>> >> setdistillerparams" \
	  -f "$INPUT"


}

helper_pdfcpu_generalShrink () {
	local INPUT="$1"
	local OUTPUT="$2"
	local PARAMS="$3"

	# @see https://pdfcpu.io/core/optimize

	# in order to make pdftk work on Ubuntu, you need to
	#	PDFCPU_VERSION=$(curl -s "https://api.github.com/repos/pdfcpu/pdfcpu/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
	#	echo $PDFCPU_VERSION
	#	wget -qO pdfcpu.tar.xz https://github.com/pdfcpu/pdfcpu/releases/latest/download/pdfcpu_${PDFCPU_VERSION}_Linux_x86_64.tar.xz
	# copy pdfcpu to ~/bin/pdfcpu

	if hash pdfcpu 2>/dev/null; then
		pdfcpu optimize $PARAMS "$INPUT" "$OUTPUT" 2>&1 # 1>/dev/null
	# else
		# echo "pdfcpu is not installed"
	fi
}


helper_qpdf_generalShrink () {
	local INPUT="$1"
	local OUTPUT="$2"
	local PARAMS="$3"

	# in order to make pdftk work on Ubuntu, you need to
	#	apt install qpdf

	if hash qpdf 2>/dev/null; then
		qpdf $PARAMS "$INPUT" "$OUTPUT"
	# else
		# echo "qpdf is not installed"
	fi
}

# -------------------------------------------------------------------------------------------------

shrink_remove_images () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript to filter out all images from the input";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "destructive";
		return;
	fi;

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dFILTERIMAGE"
}

shrink_remove_images_remove_vectors () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript to filter out all images and vectors from the input";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "destructive";
		return;
	fi;

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dFILTERIMAGE -dFILTERVECTOR"
}

shrink_images_to_50dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript to recompress all images to 50dpi";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "lowq";
		return;
	fi;

	helper_gs_shrinkImages_screen "$INPUT" "$OUTPUT" "50"
}


shrink_images_to_72dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript to recompress all images to 72dpi";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "lowq";
		return;
	fi;

	helper_gs_shrinkImages_screen "$INPUT" "$OUTPUT" "72"
}

shrink_images_to_96dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript to recompress all images to 96dpi";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "lowq";
		return;
	fi;

	helper_gs_shrinkImages_screen "$INPUT" "$OUTPUT" "96"
}

shrink_images_to_150dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript to recompress all images to 150dpi";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "default";
		return;
	fi;

	helper_gs_shrinkImages_screen "$INPUT" "$OUTPUT" "150"
}


shrink_images_to_300dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript to recompress all images to 300dpi";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "hiq";
		return;
	fi;

	helper_gs_shrinkImages_printer "$INPUT" "$OUTPUT" "300"
}


shrink_images_to_450dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript to recompress all images to 450dpi";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "hiq";
		return;
	fi;

	helper_gs_shrinkImages_printer "$INPUT" "$OUTPUT" "450"
}


shrink_images_to_600dpi () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript to recompress all images to 600dpi";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "hiq";
		return;
	fi;

	helper_gs_shrinkImages_printer "$INPUT" "$OUTPUT" "600"
}


shrink_ps2pdf_printer () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ps2pdf with printer settings";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "hiq";
		return;
	fi;

	ps2pdf -dPDFSETTINGS=/printer "$INPUT" "$OUTPUT"
}

shrink_ps2pdf_ebook () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ps2pdf with ebook settings";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "default";
		return;
	fi;

	ps2pdf -dPDFSETTINGS=/ebook "$INPUT" "$OUTPUT"
}

shrink_ps2pdf_screen () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ps2pdf with ebook settings";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "lowq";
		return;
	fi;

	ps2pdf -dPDFSETTINGS=/screen "$INPUT" "$OUTPUT"
}


shrink_convert_zip_150 () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use convert & compress as zip, 150x150";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "lowq";
		return;
	fi;


	# in order to make convert work on Ubuntu, you need to remove the restriction placed on convert for encoding PDF's:
	# comment <!-- <policy domain="coder" rights="none" pattern="PDF" /> --> into /etc/ImageMagick-6/policy.xml
	# @see https://askubuntu.com/questions/1081895/trouble-with-batch-conversion-of-png-to-pdf-using-convert

	convert -compress Zip -density 150x150 "$INPUT" "$OUTPUT"
}

shrink_convert_zip_150_ps2pdf_printer () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use convert & compress as zip, 150x150, then recompress to pdf, printer settings";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "lowq";
		return;
	fi;

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

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use pdftk to compress";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "hiq";
		return;
	fi;


	# in order to make pdftk work on Ubuntu, you need to
	#	sudo snap install pdftk

	if hash pdftk 2>/dev/null; then
		pdftk "$INPUT" output "$OUTPUT" compress
	# else
		# echo "pdftk is not installed"
	fi
}

shrink_gs_v11 () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript with ebook settings";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "default";
		return;
	fi;

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook"
}

shrink_gs_v12 () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript with screen settings";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "lowq";
		return;
	fi;

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen"
}

shrink_gs_v15 () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript with ebook settings, no embbeded fonts";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "default";
		return;
	fi;

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true "
}

shrink_gs_v16 () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use ghostscript with screen settings, no embbeded fonts";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "lowq";
		return;
	fi;

	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true "
}

# TODO: implement this, as it doesn't skip font embedding as expected, and generates errors and blank pdf's
# shrink_gs_v17 () {
# 	local INPUT="$1"
# 	local OUTPUT="$2"

# 	if [[ "$INPUT" == ".descript" ]]; then
# 		echo -ne "use ghostscript with screen settings, no embbeded fonts, v2";
# 		return;
# 	fi;
# 	if [[ "$INPUT" == ".category" ]]; then
# 		echo -ne "default";
# 		return;
# 	fi;

# 	helper_gs_generalShrink "$INPUT" "$OUTPUT" "-dCompatibilityLevel=1.4 -dPDFSETTINGS=/printer -dEmbedAllFonts=false -dSubsetFonts=true -dConvertCMYKImagesToRGB=true -dCompressFonts=true -c '.setpdfwrite <</AlwaysEmbed [/Helvetica /Times-Roman]>> setdistillerparams'"
# }

shrink_ps2pdf_v11 () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use pdf2ps & ps2pdf with screen settings";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "lowq";
		return;
	fi;

	local TMPFILE=`mktemp --tmpdir="${TMPDIR}"`;

	pdf2ps "$INPUT" "$TMPFILE"
	ps2pdf -dPDFSETTINGS=/screen "$TMPFILE" "$OUTPUT"
}

shrink_qpdf_v11 () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use qpdf with stream compression and image recompression";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "default";
		return;
	fi;

	helper_qpdf_generalShrink "$INPUT" "$OUTPUT" "--object-streams=generate --compress-streams=y --recompress-flate --compression-level=9 --optimize-images"
}

shrink_pdfcpu_v11 () {
	local INPUT="$1"
	local OUTPUT="$2"

	if [[ "$INPUT" == ".descript" ]]; then
		echo -ne "use pdfcpu, not sure what is optimizes";
		return;
	fi;
	if [[ "$INPUT" == ".category" ]]; then
		echo -ne "default";
		return;
	fi;

	helper_pdfcpu_generalShrink "$INPUT" "$OUTPUT" ""
}


ALLMETHODS=$(compgen -A function | egrep "shrink_" | tr "\n" ",");
ALLMETHODS_ARR=(${ALLMETHODS//,/ });
ALLMETHODS_CATEGORIES=();
for M in "${ALLMETHODS_ARR[@]}"; do
	C="$($M ".category" "")";
	ALLMETHODS_CATEGORIES+=( "$C" );
done;
# echo "${ALLMETHODS_CATEGORIES[*]}";

IFS=$'\n' ALLMETHODS_CATEGORIES=($(sort <<<"${ALLMETHODS_CATEGORIES[*]}" | uniq)) unset IFS;
# echo "${ALLMETHODS_CATEGORIES[*]}"; exit;

if [[ "$FILE" == "" ]]; then
   	echo "Please specify FILE=filename";

	echo "Available shrink methods:";
	for M in "${ALLMETHODS_ARR[@]}"; do
		echo "  $M";
		echo -ne "      ";
		echo -ne "[$($M ".category" "")]";
		echo -ne " $($M ".descript" "")";
		echo "";
	done;
   	exit;
fi

if [[ "$METHODS" == "all" ]]; then
	METHODS=$(compgen -A function | egrep "shrink_" | tr "\n" ",");
elif [[ "$METHODS" == "gs" ]]; then
	# everything that uses gs
	METHODS=$(compgen -A function | egrep "(shrink_.*gs_)" | tr "\n" ",");
else
	# category request
	REQUESTEDMETHOD="$METHODS";
	for C in "${ALLMETHODS_CATEGORIES[@]}"; do
		if [[ "$REQUESTEDMETHOD" == "$C" ]]; then
			METHODS="";
			for M in "${ALLMETHODS_ARR[@]}"; do
				MC="$($M ".category" "")";
				if [[ "$MC" == "$C" ]]; then
					METHODS="$METHODS,$M";
				fi;
			done;
		fi;
	done;
fi;
# else, use the list as-is




echo > "$COMMANDFILE";
METHODS_ARR=(${METHODS//,/ })

if [ "$VERBOSE" = "1" ]; then
	echo "Compressing $FILE, `du -h "$FILE" | sed -r "s/\\s+/ /g" | cut -f1 -d" "`";
	echo "  trying ${#METHODS_ARR[@]} methods";
elif [ "$VERBOSE" = "2" ]; then
	echo -e "original\t0ns\t0ns\t`du --bytes "$FILE"`";
fi

FILES_ARR=()
for M in "${METHODS_ARR[@]}"; do
	TMPFILE=`mktemp --suffix ".${M}.pdf" --tmpdir="${TMPDIR}"`;

	if [ "$VERBOSE" = "1" ]; then
		echo "(printf '    %-*s: ' 25 \"$M\" && $M \"$FILE\" \"$TMPFILE\" && du -sh \"$TMPFILE\")" >> "$COMMANDFILE";
	elif [ "$VERBOSE" = "2" ]; then
		echo "(echo -ne \"$M\t\" && echo -ne \"$((`date +%s%N`))ns\t\" && $M \"$FILE\" \"$TMPFILE\" && echo -ne \"$((`date +%s%N`))ns\t\" && du --bytes \"$TMPFILE\")" >> "$COMMANDFILE";
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

	M=`echo -ne "$TMPFILE" | sed -r "s/.+\.(shrink_.+)/\1/"`
	NNAME="${NNAME/__METHOD__/$M}";

	if [ "$VERBOSE" = "1" ]; then
		echo "--> ${NNAME}";
	fi;

	cp -f "$TMPFILE" "${NNAME}";
done;


rm "$FILELIST";
for TMPFILE in "${FILES_ARR[@]}"; do
	rm "$TMPFILE";
done;
