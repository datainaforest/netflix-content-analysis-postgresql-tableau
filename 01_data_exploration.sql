-- =====================================================
-- 01. DATA EXPLORATION
-- =====================================================

-- Preview data
SELECT *
FROM netflix_titles
LIMIT 10;

-- Total number of rows
SELECT COUNT(*) AS total_titles
FROM netflix_titles;

-- Movies vs TV Shows
SELECT
    type,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY type
ORDER BY total_titles DESC;

-- Missing values stored as empty strings
SELECT
    COUNT(*) FILTER (WHERE director = '') AS missing_director,
    COUNT(*) FILTER (WHERE country = '') AS missing_country,
    COUNT(*) FILTER (WHERE cast_members = '') AS missing_cast,
    COUNT(*) FILTER (WHERE date_added = '') AS missing_date
FROM netflix_titles;

-- Release year distribution
SELECT
    release_year,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY release_year
ORDER BY release_year;

-- Distinct duration values
SELECT DISTINCT duration
FROM netflix_titles
ORDER BY duration;
