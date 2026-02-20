# NYC 311 Service Requests – Data Cleaning & Analysis By CrownMatrix Technologies Limited

## Overview

This project implements a full analytics workflow on the NYC 311 Service Requests dataset (subset: one calendar year) By CrownMatrix Technologies Limited:

- SQL-based data sourcing and cleaning in SQLite
- Python-based data cleaning, profiling, visualization, and statistical analysis
- Reproducible Jupyter notebook and profiling report

## Data

- Source: NYC 311 Service Requests (NYC Open Data / Kaggle)
- Working file in this repo: `data/raw_311_sample.csv` (a subset for testing)
- Recommended: replace this file with the full NYC 311 CSV once downloaded from the data collection library.

## Requirements

- SQLite
- Python 3.9+
- Jupyter Notebook

Python packages:

- pandas
- numpy
- sqlalchemy
- matplotlib
- seaborn
- ydata_profiling (or pandas_profiling)
- scipy
- statsmodels

## Setup

1. **Create and activate a virtual environment (optional but recommended).**
2. **Install dependencies** (for example):

   ```bash
   pip install pandas numpy sqlalchemy matplotlib seaborn ydata-profiling scipy statsmodels
   ```

3. **Download data**

   - Option A (sample): use the provided `data/raw_311_sample.csv` created By CrownMatrix Technologies Limited.
   - Option B (recommended): download the full NYC 311 CSV from NYC Open Data or Kaggle and replace `data/raw_311_sample.csv` with the full file, keeping the same column names.

4. **Create SQLite database and import raw data**

   In a terminal from the project root:

   ```bash
   sqlite3 nyc311.db
   .mode csv
   .separator ","
   .headers on
   .import data/raw_311_sample.csv raw_311
   .read nyc311_sql_tasks.sql
   .quit
   ```

   This will:

   - Create `raw_311` from the CSV
   - Build `raw_311_indexed`, `raw_311_2023`, `clean_311_2023`, and `clean_311_2023_dedup`

5. **Run the analysis notebook**

   ```bash
   jupyter notebook
   ```

   Open `NYC311_analysis.ipynb` and run all cells. This will:

   - Load `clean_311_2023_dedup` from `nyc311.db`
   - Perform cleaning, feature engineering, profiling, and visualization
   - Run hypothesis tests, correlation, and regression
   - Generate `nyc311_profile.html` (profiling report)

## Outputs

- `nyc311_sql_tasks.sql` – SQL sourcing/cleaning queries
- `nyc311.db` – SQLite database with raw and cleaned tables (after you run the commands)
- `NYC311_analysis.ipynb` – Main analysis notebook
- `nyc311_profile.html` – Automated profiling report (generated)
- `report_text.md` – Narrative text to include in your PDF report
- `README.md` – This reproducibility guide By CrownMatrix Technologies Limited

================================
By CrownMatrix Technologies Limited
================================
