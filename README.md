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
├── SIGCSE_TS_2027_review_list_<...>.txt   list of reviews (every time)
├── SIGCSE_TS_2027_<...>.xlsx              list of submissions (only if new papers were added)
└── assignment/                            assignments, unzipped (only if assignments have changed)
    ├── assignment.csv                     who is assigned to which paper (required)
    ├── reviewer.csv                       PC members: name, email, role (required)
    ├── conflict.csv                       conflicts of interest     ┐
    ├── bid.csv                            reviewer bids             │ optional, used by the
    ├── reviewer_topic.csv                 topics of each reviewer   │ "Needs help" tab
    └── submission_topic.csv               topics of each paper      ┘
```

If there are several files of the same kind, the newest one is used.
The optional files come in the same archive; without them the "Needs help" tab still works,
but candidates are not filtered by conflicts or ranked by bids and topics
(see [the "Needs help" tab](#needs-help-tab) below for details).

How to download the list of reviews:

1. **Administration -> List of reviews**.
2. Select all options: **show author names**, **show reviewer names**, **include comments**,
   **download as an attachment**.
3. Click **Generate list**.

How to download the list of submissions:

1. **Submissions in Excel**.
2. Leave all checkboxes unselected.
3. Click **Download**.

Assignments: **Assignment -> Download in CSV**, then unzip the archive into `input/assignment/`.

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

## "Needs help" tab

Lists submissions with fewer than N reviewers assigned (default 5, change with `--min-reviewers N`)
and suggests who could review them.

- **Needed role**: a senior PC if the paper has none yet, otherwise a PC member.
- **Two candidate pools** of that role, shown as separate columns and tables:
  - *1-M assignments*: reviewers with at least 1 and at most M assignments
    (default M = 7, change with `--max-assigned M`);
  - *no assignments yet*: reviewers with 0 assignments. They are kept apart because there may be a
    reason they can't review (e.g. they joined late or declined).
- **Top 3 candidates per paper, picked separately within each pool**, excluding conflicts and reviewers already
  assigned to the paper, ranked by bid (yes > maybe > none > no), then by the number of matching
  topics, then by current load.
- **Suggested for (#)** in the pool shows which papers each person was suggested for, so you can spread
  the load if the same person tops several papers.

Bids, conflicts and topics come from the same Assignment -> Download in CSV archive
(`bid.csv`, `conflict.csv`, `reviewer_topic.csv`, `submission_topic.csv`).

## License

Copyright 2026 Anastasiia Birillo. Licensed under the [Apache License 2.0](LICENSE).
