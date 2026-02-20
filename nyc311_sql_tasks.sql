-- nyc311_sql_tasks.sql
-- NYC 311 Service Requests – SQL sourcing and cleaning
--
-- NOTES:
-- - This script is written for SQLite.
-- - It assumes the raw CSV has already been imported into a table called raw_311.
-- - The Kaggle/NYC Open Data file typically has column names like:
--   "Unique Key", "Created Date", "Closed Date", "Agency", "Agency Name",
--   "Complaint Type", "Descriptor", "Incident Zip", "Street Name",
--   "Cross Street 1", "Cross Street 2", "City", "Borough", "Status",
--   "Resolution Description", "Resolution Action Updated Date",
--   "Latitude", "Longitude", "Location", etc.
-- - If your column names differ, adjust queries accordingly.

-----------------------------------------------------------------------
-- 0. Example of loading the CSV into SQLite as raw_311 (run manually)
-----------------------------------------------------------------------
-- In the sqlite3 CLI, run something like:
--
-- .mode csv
-- .separator ","
-- .headers on
-- .import data\raw_311_sample.csv raw_311
--
-- After import, raw_311 contains the raw dataset and must NEVER be modified.

-----------------------------------------------------------------------
-- 1. Basic inspection helpers (can be run interactively)
-----------------------------------------------------------------------
-- PRAGMA table_info(raw_311);
-- SELECT COUNT(*) AS raw_row_count FROM raw_311;

-----------------------------------------------------------------------
-- 2. Create an indexed copy of raw_311 (optional but useful)
-----------------------------------------------------------------------
DROP TABLE IF EXISTS raw_311_indexed;

CREATE TABLE raw_311_indexed AS
SELECT *
FROM raw_311;

-- Add indexes on commonly queried columns
CREATE INDEX IF NOT EXISTS idx_raw_unique_key   ON raw_311_indexed("Unique Key");
CREATE INDEX IF NOT EXISTS idx_raw_created_date ON raw_311_indexed("Created Date");
CREATE INDEX IF NOT EXISTS idx_raw_closed_date  ON raw_311_indexed("Closed Date");
CREATE INDEX IF NOT EXISTS idx_raw_borough      ON raw_311_indexed("Borough");
CREATE INDEX IF NOT EXISTS idx_raw_latitude     ON raw_311_indexed("Latitude");
CREATE INDEX IF NOT EXISTS idx_raw_longitude    ON raw_311_indexed("Longitude");

-----------------------------------------------------------------------
-- 3. Create a subset for a single year (e.g., 2023)
-----------------------------------------------------------------------
DROP TABLE IF EXISTS raw_311_2023;

CREATE TABLE raw_311_2023 AS
SELECT *
FROM raw_311_indexed
WHERE substr("Created Date", 7, 4) = '2023';
-- Explanation:
--   The raw "Created Date" is typically in the format: MM/DD/YYYY HH:MM:SS AM
--   substr("Created Date", 7, 4) extracts the YYYY part.

-- Quick validation
-- SELECT COUNT(*) AS raw_2023_rows FROM raw_311_2023;

-----------------------------------------------------------------------
-- 4. Create a cleaned / sourced table for analysis
-----------------------------------------------------------------------

DROP TABLE IF EXISTS clean_311_2023;

-- Simplified cleaning for robustness: keep all rows with a non-empty Created Date
CREATE TABLE clean_311_2023 AS
SELECT
    CAST("Unique Key" AS INTEGER) AS unique_key,
    "Created Date" AS created_datetime_text,
    "Closed Date"  AS closed_datetime_text,
    datetime("Created Date") AS created_datetime,
    datetime("Closed Date")  AS closed_datetime,
    date(datetime("Created Date"))           AS created_date,
    strftime('%Y', datetime("Created Date")) AS created_year,
    strftime('%m', datetime("Created Date")) AS created_month,
    strftime('%d', datetime("Created Date")) AS created_day,
    strftime('%H', datetime("Created Date")) AS created_hour,
    strftime('%w', datetime("Created Date")) AS created_weekday,
    TRIM("Complaint Type")  AS complaint_type,
    TRIM("Descriptor")      AS descriptor,
    TRIM("Agency")          AS agency,
    TRIM("Agency Name")     AS agency_name,
    TRIM("Status")          AS status,
    TRIM("Borough")         AS borough,
    TRIM("Incident Zip")    AS incident_zip,
    TRIM("Street Name")     AS street_name,
    TRIM("Cross Street 1")  AS cross_street_1,
    TRIM("Cross Street 2")  AS cross_street_2,
    TRIM("City")            AS city,
    "Latitude"              AS latitude,
    "Longitude"             AS longitude,
    TRIM("Resolution Description")         AS resolution_description,
    TRIM("Resolution Action Updated Date") AS resolution_action_updated_date_text,
    CASE
        WHEN "Complaint Type" LIKE '%Noise%' THEN 'Noise'
        WHEN "Complaint Type" LIKE '%Heat%' OR "Complaint Type" LIKE '%Hot%' THEN 'Heating'
        WHEN "Complaint Type" LIKE '%Plumbing%' OR "Complaint Type" LIKE '%Water%' THEN 'Plumbing/Water'
        WHEN "Complaint Type" LIKE '%Street Light%' OR "Complaint Type" LIKE '%Traffic%' THEN 'Street/Traffic'
        WHEN "Complaint Type" LIKE '%Sanitation%' OR "Complaint Type" LIKE '%Litter%' THEN 'Sanitation'
        ELSE 'Other'
    END AS complaint_group,
    CASE
        WHEN "Closed Date" IS NULL OR TRIM("Closed Date") = '' THEN 1
        ELSE 0
    END AS is_open
FROM raw_311_2023
WHERE "Created Date" IS NOT NULL AND TRIM("Created Date") <> '';

-- Quick validation of row count after initial cleaning
-- SELECT COUNT(*) AS clean_2023_rows FROM clean_311_2023;

-----------------------------------------------------------------------
-- 5. Handle duplicate records by unique_key
-----------------------------------------------------------------------

DROP TABLE IF EXISTS clean_311_2023_dedup;

-- Simple deduplication: keep one row per unique_key (sufficient for the sample data)
CREATE TABLE clean_311_2023_dedup AS
SELECT *
FROM clean_311_2023
GROUP BY unique_key;

CREATE INDEX IF NOT EXISTS idx_clean_dedup_unique_key ON clean_311_2023_dedup(unique_key);

-----------------------------------------------------------------------
-- 6. Basic validation checks on the cleaned table
-----------------------------------------------------------------------

-- 6.1 Invalid coordinates remaining (should be very small or zero)
SELECT COUNT(*) AS invalid_coords
FROM clean_311_2023_dedup
WHERE NOT (
    latitude  BETWEEN 40.4 AND 41.1
    AND longitude BETWEEN -74.3 AND -73.5
);

-- 6.2 Missing key categorical fields
SELECT
    SUM(CASE WHEN complaint_type IS NULL OR complaint_type = '' THEN 1 ELSE 0 END) AS missing_complaint_type,
    SUM(CASE WHEN borough        IS NULL OR borough        = '' THEN 1 ELSE 0 END) AS missing_borough
FROM clean_311_2023_dedup;

-- 6.3 Distribution of complaint groups (sanity check)
SELECT complaint_group, COUNT(*) AS cnt
FROM clean_311_2023_dedup
GROUP BY complaint_group
ORDER BY cnt DESC;

-----------------------------------------------------------------------
-- END OF FILE
-----------------------------------------------------------------------
