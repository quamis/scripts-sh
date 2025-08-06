# Google Takeout Merger

This script merges new Google Takeout data into an existing photo collection, handling duplicates intelligently.

## ⚠️ IMPORTANT: Path Verification

**ALWAYS double-check your D2 path before running!** Make sure you're pointing to the correct destination folder.

Common paths on this system:
- **D2 (destination)**: `/media/BIG/picturesFromPhone/` - Main photo collection
- **D1 (source)**: `/media/BIG/tmp/` - Temporary extraction location
- **Alternative**: `/media/lucian/BIG2T1/picturesFromPhone/` - Secondary location (verify which one you want!)

## Prerequisites

1. Extract your Google Takeout files:
```bash
tar -xzvf ./takeout-1.tgz && tar -xzvf ./takeout-2.tgz
```

2. Create the required lock file in your destination:
```bash
touch "/media/BIG/picturesFromPhone/google-takeout-PROFILE/original_takeout.lock"
```

## Usage Examples

```bash
# Quamis profile (trash: /media/BIG/tmp/google-takeout-quamis/trash/)
./merge.auto.sh D1='/media/BIG/tmp/google-takeout-quamis/Takeout/Google Photos' D2='/media/BIG/picturesFromPhone/google-takeout-quamis' PROFILE="quamis" RUN_MODE=safe TRASH='/media/BIG/tmp/google-takeout-quamis/trash/'

# Andreea profile (trash: /media/BIG/tmp/google-takeout-sirbuandreea/trash/)
./merge.auto.sh D1='/media/BIG/tmp/google-takeout-sirbuandreea/Takeout/Google Photos' D2='/media/BIG/picturesFromPhone/google-takeout-sirbuandreea' PROFILE="sirbuandreea" RUN_MODE=safe TRASH='/media/BIG/tmp/google-takeout-sirbuandreea/trash/'

# George profile (trash: /media/BIG/tmp/google-takeout-sirbu.george.radu/trash/)
./merge.auto.sh D1='/media/BIG/tmp/google-takeout-sirbu.george.radu/Takeout/Google Photos' D2='/media/BIG/picturesFromPhone/google-takeout-sirbu.george.radu' PROFILE="sirbu.george.radu" RUN_MODE=safe TRASH='/media/BIG/tmp/google-takeout-sirbu.george.radu/trash/'
```

## Run Modes

- `RUN_MODE=dry-run` - Show what would be done (safe preview)
- `RUN_MODE=safe` - Move deleted files to `./trash/` folder
- `RUN_MODE=unsafe` - Permanently delete files (use with caution)

## Trash Folder Location

For better organization, each profile has its own trash folder:
- **Quamis**: `/media/BIG/tmp/google-takeout-quamis/trash/`
- **Andreea**: `/media/BIG/tmp/google-takeout-sirbuandreea/trash/`
- **George**: `/media/BIG/tmp/google-takeout-sirbu.george.radu/trash/`

These directories have been created and are ready to use.

## Post-Processing

```bash
# Clean up trash after verifying results (choose the appropriate profile)
rm /media/BIG/tmp/google-takeout-quamis/trash/*
rm /media/BIG/tmp/google-takeout-sirbuandreea/trash/*
rm /media/BIG/tmp/google-takeout-sirbu.george.radu/trash/*
```

## What the Script Does

1. **Phase 1.1**: Deletes identical files from D1 (same name + size in both locations)
2. **Phase 1.2**: Deletes files from D1 that were previously moved (based on log)
3. **Phase 2**: Moves new files from D1 to D2
4. **Phase 3**: For changed files (same name, different size):
   - Moves larger version to D2
   - Deletes smaller version from D1
5. **Phase 4**: Moves JSON metadata files from D1 to D2

## Google Photos Storage Management

After merging, optimize your Google Photos storage:
1. Go to https://photos.google.com/settings
2. Click "Manage storage"
3. Visit https://photos.google.com/quotamanagement
4. Click "Recover storage" to compress existing photos
