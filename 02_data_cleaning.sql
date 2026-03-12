-- =====================================================
-- 02. DATA CLEANING
-- =====================================================

-- Convert empty strings to NULL
UPDATE netflix_titles
SET director = NULL
WHERE TRIM(director) = '';

UPDATE netflix_titles
SET country = NULL
WHERE TRIM(country) = '';

UPDATE netflix_titles
SET cast_members = NULL
WHERE TRIM(cast_members) = '';

UPDATE netflix_titles
SET date_added = NULL
WHERE TRIM(date_added) = '';

-- Add cleaned date column
ALTER TABLE netflix_titles
ADD COLUMN IF NOT EXISTS date_added_clean DATE;

UPDATE netflix_titles
SET date_added_clean = TO_DATE(date_added, 'Month DD, YYYY')
WHERE date_added IS NOT NULL;

-- Add duration numeric value
ALTER TABLE netflix_titles
ADD COLUMN IF NOT EXISTS duration_value INT;

UPDATE netflix_titles
SET duration_value = SPLIT_PART(duration, ' ', 1)::INT
WHERE duration IS NOT NULL;

-- Add duration unit
ALTER TABLE netflix_titles
ADD COLUMN IF NOT EXISTS duration_unit TEXT;

UPDATE netflix_titles
SET duration_unit = SPLIT_PART(duration, ' ', 2)
WHERE duration IS NOT NULL;

-- Standardize duration labels
UPDATE netflix_titles
SET duration_unit = 'Seasons'
WHERE duration_unit = 'Season';

-- Validation checks
SELECT
    COUNT(*) FILTER (WHERE director IS NULL) AS missing_director,
    COUNT(*) FILTER (WHERE country IS NULL) AS missing_country,
    COUNT(*) FILTER (WHERE cast_members IS NULL) AS missing_cast,
    COUNT(*) FILTER (WHERE date_added IS NULL) AS missing_date
FROM netflix_titles;

SELECT
    type,
    duration_unit,
    ROUND(AVG(duration_value), 2) AS avg_duration
FROM netflix_titles
GROUP BY type, duration_unit
ORDER BY type;

SELECT
    MIN(date_added_clean) AS first_added,
    MAX(date_added_clean) AS last_added
FROM netflix_titles;
