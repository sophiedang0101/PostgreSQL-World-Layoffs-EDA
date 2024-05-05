SELECT * FROM world_layoffs.layoffs;

CREATE TABLE world_layoffs.layoffs_staging AS
SELECT * FROM world_layoffs.layoffs;

SELECT * FROM world_layoffs.layoffs_staging;

-- Check for duplicates.
SELECT *
FROM (
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,"date", stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;

-- Create CTE for duplicates.
WITH duplicate_cte AS
(
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,"date", stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Create another staging table with a new column 'row_num' added.
CREATE TABLE world_layoffs.layoffs_staging2(
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT,
    percentage_laid_off TEXT,
    date TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions DECIMAL,
	row_num INT
);

-- Insert data into new table and delete duplicate rows.
INSERT INTO world_layoffs.layoffs_staging2
SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,"date", stage, country, funds_raised_millions
			) AS row_num
FROM 
	world_layoffs.layoffs_staging;


DELETE
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;


-- Standardizing Data.
SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging2;

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET company = TRIM(company);

UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

UPDATE world_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Change the date format.
SELECT "date",
       TO_DATE("date", 'MM/DD/YYYY')
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET "date" = TO_DATE("date", 'MM/DD/YYYY');

ALTER TABLE world_layoffs.layoffs_staging2
ALTER COLUMN "date" TYPE DATE
USING "date"::DATE;

-- Addressing NULL and blanks values.
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Set the blanks to nulls since those are typically easier to work with.
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL OR industry = '';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Airbnb';

-- Write a query to check if there is another row with the same company name,
-- it will update it to the non-null industry values.
-- This makes it easy so if there were thousands we wouldn't have to manually check them all.

SELECT t1.industry, t2.industry
FROM world_layoffs.layoffs_staging2 AS t1
JOIN world_layoffs.layoffs_staging2 AS t2
	ON t1.company = t2.company
	AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE world_layoffs.layoffs_staging2 t1
SET industry = t2.industry
FROM world_layoffs.layoffs_staging2 t2
WHERE t1.company = t2.company
  AND t1.location = t2.location
  AND t1.industry IS NULL
  AND t2.industry IS NOT NULL;


-- Delete useless data we can't really use.
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;

SELECT * 
FROM world_layoffs.layoffs_staging2;