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

### Command-line options

All options are optional; with none, the script uses the defaults below.

| Option | Default | Description |
|---|---|---|
| `reviews_txt` (positional) | newest `*review_list*.txt` in the input folder | list of reviews to use |
| `--input-dir DIR` | `input/` | folder with EasyChair exports |
| `--output-dir DIR` | `output/` | folder for the generated xlsx |
| `-o`, `--output FILE` | `<output dir>/review_stats_<YYYY-MM-DD_HHMM>.xlsx` | exact output path (overrides `--output-dir`) |
| `--submissions FILE` | newest `SIGCSE_TS_2027_*.xlsx` in the input folder | list of submissions |
| `--assignment-dir DIR` | `<input dir>/assignment` | folder with the assignment CSVs |
| `--min-reviewers N` | `5` | submissions with fewer assigned reviewers go to the "Needs help" tab |
| `--max-assigned M` | `7` | "Needs help" candidates: reviewers with 1..M assignments (plus a separate pool with 0) |
| `-h`, `--help` | | show the help and exit |

Relative paths are resolved against the current folder; the default `input/` and `output/` are
always next to `build_stats.py`.

Examples:

```
.venv/bin/python build_stats.py --min-reviewers 4 --max-assigned 6
.venv/bin/python build_stats.py --input-dir ~/Downloads/easychair -o ~/Desktop/stats.xlsx
```

With Docker, add the options after the image name. Paths are inside the container,
so keep using the mounted `/app/input` and `/app/output`:

```
docker run --rm --user "$(id -u):$(id -g)" -e TZ=Europe/Berlin \
  -v "$PWD/input:/app/input:ro" -v "$PWD/output:/app/output" \
  sigcse-review-stats --min-reviewers 4 --max-assigned 6
```

## 3. Import into Google Sheets

The result is written to `output/review_stats_<date>_<time>.xlsx`.
In Google Sheets: **File -> Import -> Upload -> Replace spreadsheet**. The spreadsheet link stays the same.

## Output format

One xlsx file, `output/review_stats_<YYYY-MM-DD_HHMM>.xlsx`, with five tabs:
Summary, Submissions, Reviewers, Needs help, All reviews. Values below are placeholders.
On Submissions, Reviewers and All reviews the header row is frozen and has a filter.

### Colors

Rows on Submissions, Reviewers and Needs help are colored by progress
(submitted reviews out of assigned ones):

| Color | Status label | Meaning |
|---|---|---|
| red | `Not started` | no reviews submitted yet |
| yellow | `Less than half` | less than half submitted |
| light green | `Half or more` | half or more, but not all |
| dark green | `Done` | all submitted |
| grey | `No assignments` | only in the "Needs help" candidate pool: nothing assigned yet |

Rows are sorted in the same order; within each group, by completion percentage.

### Summary

Two-column key/value list:

- `EasyChair review export` (date from the TXT), `Generated at`;
- `Submissions`, `Reviews assigned`, `Reviews submitted`, `Progress` (%),
  `Submissions with < N reviewers assigned`;
- `Submissions by status` and `Reviewers by status`: count per status, colored as above;
- `Reviews submitted per paper`: how many papers have 0, 1, 2, ... reviews;
- `Warnings` (only if any): reviews whose reviewer is not in `reviewer.csv`, or reviews for a paper
  the reviewer is not assigned to (these are counted as an extra assignment).

### Submissions

One row per submission (all papers from the submissions xlsx and `assignment.csv`).

| Column | Content |
|---|---|
| `Status` | progress status, see Colors |
| `#` | paper number |
| `Title`, `Authors` | from the submissions xlsx |
| `Submitted` | number of submitted reviews |
| `Assigned` | number of assigned reviewers |
| `%` | Submitted / Assigned |
| `Senior PC submitted` | `yes` / `no`, or `n/a` if no senior PC is assigned |
| `Scores`, `Avg score` | `TOTAL SCORE` of each review (comma-separated) and their average |
| `Familiarity`, `Avg familiarity` | familiarity (1-5) of each review and their average |
| `Submitted by` | `<reviewer> (<score>)`, comma-separated |
| `Pending` | names of assigned reviewers who haven't submitted yet |

### Reviewers

One row per reviewer with at least one assignment.

| Column | Content |
|---|---|
| `Status` | progress status, see Colors |
| `Reviewer`, `Email`, `Role` | from `reviewer.csv`; role is `PC member`, `senior PC` or `track chair` |
| `Assigned`, `Submitted`, `Remaining` | number of papers |
| `%` | Submitted / Assigned |
| `Pending papers (#)`, `Submitted papers (#)` | paper numbers, comma-separated |

### "Needs help" tab

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

The tab has three sections one below another, each with a bold title row
(if no paper needs help, it has a single line saying so instead):

1. **`Submissions with fewer than N reviewers assigned (<count>)`**: the same data as on the
   Submissions tab, plus:

   | Column | Content |
   |---|---|
   | `Assigned` | number of assigned reviewers |
   | `Missing` | N - Assigned |
   | `Needed role` | `PC member` or `senior PC` |
   | `Candidate 1..3 (1-M assigned)` | top 3 from the first pool |
   | `Candidate 1..3 (0 assigned)` | top 3 from the second pool |

   Each candidate cell reads
   `<name> (<k> assigned; bid: <bid>; <n> matching topics: <topic>, <topic>)`;
   `bid` is shown only if there is one, and the topics part becomes `0 matching topics` or
   `no topics selected`. If a pool has fewer than 3 eligible people, the next cell says
   `no other eligible candidates` (or `no eligible candidates`).
2. **`Candidate pool: 1-M assignments (<role>: <count> people with <min>-<max> assigned)`**
3. **`Candidate pool: no assignments yet (<role>: <count> people)`**

   Both pool sections have the Reviewers tab columns, plus:

   | Column | Content |
   |---|---|
   | `Topics selected` | how many topics the reviewer selected (0 = none) |
   | `Suggested for (#)` | paper numbers where the reviewer is among the top 3 |

   Rows are sorted by number of assignments, then by name.

### All reviews

One row per submitted review, sorted by paper number and review number.

| Column | Content |
|---|---|
| `#`, `Title` | paper |
| `Reviewer`, `Role` | reviewer and their role (`?` if not found in `reviewer.csv`) |
| `Review #` | review number within the paper |
| `Score` | `TOTAL SCORE` |
| `Familiarity` | full familiarity text, e.g. `<1-5> (<label>)` |
| *(other header fields)* | one column per other `Key: value` line from the review header, e.g. `Checked for Hallucinated References?` |
| `Review text` | the `SUMMARY` section |
| `Confidential remarks for PC` | the `CONFIDENTIAL REMARKS FOR THE PROGRAM COMMITTEE` section |

Long texts are cut at 45,000 characters to stay under the Google Sheets cell limit (50,000).

## Input formats

The exports are not committed, so this section records their format as of SIGCSE TS 2027
(EasyChair, October 2026). Values below are placeholders. If EasyChair changes a format,
the function to adapt is named for each file.

### List of reviews: `*review_list*.txt`

Plain text, UTF-8. Parsed by `parse_reviews()`.

```
LIST OF REVIEWS

This list of reviews is generated by EasyChair for <chair name> on <YYYY-MM-DD>.

REVIEWS


*********************** PAPER <paper #> ***********************
AUTHORS: <author 1>, <author 2> and <author 3>
TITLE: <title>
CONFLICT OF INTERESTS: <PC member>, <PC member>        (only if there are conflicts)
PRELIMINARY DECISION: <decision, e.g. "no decision">
================== SUMMARY OF REVIEWS =================
<reviewer name>: <total score>
...

++++++++++ REVIEW <k> (<reviewer name>) +++++++++
TOTAL SCORE: <integer>
Familiarity: <1-5> (<text label>)
Checked for Hallucinated References?: <yes/no>
---- SUMMARY ----
<free text, multiple lines>
---- HALLUCINATED REFERENCES LIST ----
<free text>
---- CONFIDENTIAL REMARKS FOR THE PROGRAM COMMITTEE ----
<free text>

++++++++++ REVIEW <k+1> (<reviewer name>) +++++++++
...
*********************** PAPER <next paper #> ***********************
...
```

What the script relies on:

- the date in the `generated by EasyChair for ... on <date>` line (shown as the export date);
- paper blocks start with a line of `*` around `PAPER <number>`;
- review blocks start with a line of `+` around `REVIEW <k> (<reviewer name>)`;
  the reviewer name must match the name in `reviewer.csv`;
- review header lines are `Key: value` up to the first `---- ... ----` line. `TOTAL SCORE` and
  `Familiarity` (leading number) are parsed explicitly; any other header key (e.g. a new score
  field) becomes its own column on the "All reviews" tab automatically;
- sections are `---- <NAME> ----`; `SUMMARY` and `CONFIDENTIAL REMARKS FOR THE PROGRAM COMMITTEE`
  go to the "All reviews" tab (constant `sec_keys` in `build()`).

Papers without reviews are not listed in this file.

### List of submissions: `SIGCSE_TS_2027_*.xlsx`

One worksheet, first row is the header. Parsed by `read_submissions_xlsx()`, which reads the
xlsx XML directly because EasyChair writes styles that `openpyxl` can't open.

| Column | Example | Used |
|---|---|---|
| `#` | `<paper #>` | yes, paper number |
| `Authors` | `<author 1>, <author 2> and <author 3>` | yes |
| `Title` | `<title>` | yes |
| `Poster` | `✔` (track mark) | no |

Columns are looked up by header name, so extra columns or a different order are fine.

### Assignment archive: `assignment/*.csv`

All files are comma-separated, UTF-8, **without a header row**. Reviewer ids are EasyChair's
internal PC member ids (not names) and are the same across all files. Parsed by `read_pc()`
(required files) and `read_matching()` (optional files).

| File | Columns | Notes |
|---|---|---|
| `reviewer.csv` | `reviewer id, name, email, role` | role is `pc`, `senior` or `chair` (mapped in `ROLE_NAMES`) |
| `assignment.csv` | `reviewer id, paper #` | one row per assignment |
| `conflict.csv` | `reviewer id, paper #` | one row per conflict of interest |
| `reviewer_topic.csv` | `reviewer id, topic` | one row per selected topic |
| `submission_topic.csv` | `paper #, topic` | one row per paper topic; topic names match `reviewer_topic.csv` |
| `bid.csv` | `reviewer id, paper #, bid` | was empty in 2027, so the format is assumed: bid is `yes`, `maybe`, `no` or `conflict` (weights in `BID_WEIGHTS`) |

## License

Copyright 2026 Anastasiia Birillo. Licensed under the [Apache License 2.0](LICENSE).
