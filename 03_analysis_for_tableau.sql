-- =====================================================
-- 03. ANALYSIS FOR TABLEAU EXPORT
-- =====================================================

-- -----------------------------------------------------
-- 1. KPI SUMMARY
-- Export as: kpi_summary.csv
-- -----------------------------------------------------
SELECT
    COUNT(*) AS total_titles,
    COUNT(*) FILTER (WHERE type = 'Movie') AS total_movies,
    COUNT(*) FILTER (WHERE type = 'TV Show') AS total_tv_shows,
    ROUND(AVG(duration_value) FILTER (WHERE type = 'Movie'), 2) AS avg_movie_duration_min,
    ROUND(AVG(duration_value) FILTER (WHERE type = 'TV Show'), 2) AS avg_tv_show_seasons
FROM netflix_titles;


-- -----------------------------------------------------
-- 2. TITLES ADDED BY YEAR
-- Export as: titles_by_year.csv
-- -----------------------------------------------------
SELECT
    EXTRACT(YEAR FROM date_added_clean)::INT AS added_year,
    type,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE date_added_clean IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added_clean), type
ORDER BY added_year, type;


-- -----------------------------------------------------
-- 3. TOP COUNTRIES BY SHARE OF TITLES
-- Export as: country_share_top10.csv
-- -----------------------------------------------------
WITH split_countries AS (
    SELECT DISTINCT
        show_id,
        TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS country
    FROM netflix_titles
    WHERE country IS NOT NULL
      AND TRIM(country) <> ''
),
country_counts AS (
    SELECT
        country,
        COUNT(DISTINCT show_id) AS total_titles
    FROM split_countries
    GROUP BY country
),
total_titles_base AS (
    SELECT COUNT(DISTINCT show_id) AS total_titles_all
    FROM netflix_titles
)
SELECT
    c.country,
    c.total_titles,
    ROUND(100.0 * c.total_titles / t.total_titles_all, 2) AS pct_of_all_titles,
    ROW_NUMBER() OVER (ORDER BY c.total_titles DESC) AS rank_num
FROM country_counts c
CROSS JOIN total_titles_base t
ORDER BY rank_num
LIMIT 10;


-- -----------------------------------------------------
-- 4. TOP GENRES BY CONTENT TYPE (TOP 10)
-- Export as: genre_share_top10_by_type.csv
-- -----------------------------------------------------
WITH split_genres AS (
    SELECT
        type,
        TRIM(UNNEST(STRING_TO_ARRAY(listed_in, ','))) AS genre
    FROM netflix_titles
    WHERE listed_in IS NOT NULL
),
genre_counts AS (
    SELECT
        type,
        genre,
        COUNT(*) AS total_titles
    FROM split_genres
    GROUP BY type, genre
),
genre_pct AS (
    SELECT
        type,
        genre,
        total_titles,
        ROUND(
            100.0 * total_titles / SUM(total_titles) OVER (PARTITION BY type),
            2
        ) AS pct_of_type
    FROM genre_counts
),
ranked_genres AS (
    SELECT
        type,
        genre,
        total_titles,
        pct_of_type,
        ROW_NUMBER() OVER (PARTITION BY type ORDER BY total_titles DESC) AS rank_num
    FROM genre_pct
)
SELECT
    type,
    genre,
    total_titles,
    pct_of_type,
    rank_num
FROM ranked_genres
WHERE rank_num <= 10
ORDER BY type, rank_num;


-- -----------------------------------------------------
-- 5. RELEASE GAP DISTRIBUTION
-- Export as: release_gap_pct.csv
-- -----------------------------------------------------
WITH release_gap_counts AS (
    SELECT
        type,
        CASE
            WHEN EXTRACT(YEAR FROM date_added_clean) - release_year = 0 THEN 'Same year'
            WHEN EXTRACT(YEAR FROM date_added_clean) - release_year BETWEEN 1 AND 2 THEN '1-2 years'
            WHEN EXTRACT(YEAR FROM date_added_clean) - release_year BETWEEN 3 AND 5 THEN '3-5 years'
            WHEN EXTRACT(YEAR FROM date_added_clean) - release_year BETWEEN 6 AND 10 THEN '6-10 years'
            ELSE '10+ years'
        END AS release_gap,
        COUNT(*) AS total_titles
    FROM netflix_titles
    WHERE date_added_clean IS NOT NULL
    GROUP BY type, release_gap
)
SELECT
    type,
    release_gap,
    total_titles,
    ROUND(
        100.0 * total_titles / SUM(total_titles) OVER (PARTITION BY type),
        2
    ) AS pct_of_type
FROM release_gap_counts
ORDER BY type, total_titles DESC;
