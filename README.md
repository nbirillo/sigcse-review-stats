Warning: this script was fully vibe-coded with Claude Code

# SIGCSE TS 2027 (Posters) Review Statistics

Turns EasyChair exports into a spreadsheet with review progress per submission and per reviewer,
ready to import into Google Sheets.

## Project layout

```
build_stats.py      the script
requirements.txt    Python dependencies
Dockerfile          image to run the script without a local Python environment
LICENSE             Apache License 2.0
input/              put EasyChair exports here
output/             generated spreadsheets appear here
```

`input/` and `output/` are git-ignored: they contain confidential review data.

## 1. Put EasyChair exports into `input/`

```
input/
├── SIGCSE_TS_2027_review_list_<...>.txt   Reviews -> List of reviews (every time)
├── SIGCSE_TS_2027_<...>.xlsx              list of submissions (only if new papers were added)
└── assignment/                            Assignment -> Download in CSV, unzipped
    ├── assignment.csv                     (only if assignments have changed)
    └── reviewer.csv
```

If there are several files of the same kind, the newest one is used.

## 2. Run the script

### Option A: Docker (no Python setup needed)

Build the image once:

```
docker build -t sigcse-review-stats .
```

Run it from the project folder:

```
docker run --rm --user "$(id -u):$(id -g)" -e TZ=Europe/Berlin \
  -v "$PWD/input:/app/input:ro" -v "$PWD/output:/app/output" \
  sigcse-review-stats
```

`TZ` only affects the "Generated at" timestamp and the output file name.

### Option B: local Python

```
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python build_stats.py
```

Run `build_stats.py --help` for options (custom input/output folders, explicit file paths).

## 3. Import into Google Sheets

The result is written to `output/review_stats_<date>_<time>.xlsx`.
In Google Sheets: **File -> Import -> Upload -> Replace spreadsheet**. The spreadsheet link stays the same.

## Colors

| Color | Meaning |
|---|---|
| red | no reviews submitted yet |
| yellow | less than half submitted |
| light green | half or more, but not all |
| dark green | all submitted |

Rows are sorted in the same order; within each group, by completion percentage.

## License

Copyright 2026 Anastasiia Birillo. Licensed under the [Apache License 2.0](LICENSE).
