# dependencies
```sh
apt install gs pdftk qpdf
```

# usage:
```sh
FILE="xyz.pdf";
pdf.autoShrinkOneFile.sh METHODS="shrink_images_to_300dpi,shrink_ps2pdf_printer,shrink_recompress_v40" KEEP=smaller RUN_MODE=parallel FILE="$FILE"

pdf.autoShrinkOneFile.sh METHODS="shrink_images_to_75dpi,shrink_images_to_150dpi,shrink_images_to_300dpi,shrink_ps2pdf_printer,shrink_ps2pdf_ebook,shrink_pdftk,shrink_recompress_v10,shrink_recompress_v11,shrink_recompress_v15,shrink_recompress_v16,shrink_recompress_v17,shrink_recompress_v18,shrink_recompress_v30,shrink_recompress_v40" KEEP=smaller RUN_MODE=parallel FILE="$FILE"

```