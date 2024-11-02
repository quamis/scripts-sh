```bash
./merge.auto.sh D1='/media/BIG/tmp/google-takeout-quamis/Takeout/Google Photos' D2='/media/lucian/BIG2T1/picturesFromPhone/google-takeout-quamis'  PROFILE="quamis" RUN_MODE=safe

rm ./trash/*

./merge.auto.sh D1='/media/BIG/tmp/google-takeout-sirbuandreea/Takeout/Google Photos' D2='/media/lucian/BIG2T1/picturesFromPhone/google-takeout-sirbuandreea'  PROFILE="sirbuandreea" RUN_MODE=safe

./merge.auto.sh D1='/media/BIG/tmp/google-takeout-sirbu.george.radu/Takeout/Google Photos' D2='/media/lucian/BIG2T1/picturesFromPhone/google-takeout-sirbu.george.radu'  PROFILE="sirbu.george.radu" RUN_MODE=safe

```

Then go to https://photos.google.com/settings then "Manage storage" then https://photos.google.com/quotamanagement and click "recover storage" to compress existing photos
