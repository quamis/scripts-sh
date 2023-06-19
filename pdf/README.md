# dependencies
```sh
apt install gs pdftk qpdf
```

# usage:
```sh
pdf.autoShrinkOneFile.sh METHODS="shrink_images_to_75dpi,shrink_images_to_150dpi,shrink_images_to_300dpi,shrink_ps2pdf_printer,shrink_ps2pdf_ebook,shrink_convert_zip_150,shrink_convert_zip_300_ps2pdf_printer,shrink_pdftk,qpdf_recompress_v10" KEEP=smaller FILE=in1.pdf
```