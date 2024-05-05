-- 1. Highest total and percentage laid off.
select
	max(total_laid_off),
	max(percentage_laid_off)
from world_layoffs.layoffs_staging2;


-- 2. Top three companies include Amazon, Google, and Meta.
-- Amazon laid off a total of 18,150 people, Google laid off 12,000, and Meta laid off 11,000.
select company, sum(total_laid_off) 
FROM world_layoffs.layoffs_staging2
group by company
order by 2 desc;



-- 3. Industry with highest laid offs: Consumer
-- Industry with lowest laid offs: Manufacturing
select industry, sum(total_laid_off)
from world_layoffs.layoffs_staging2
group by industry
order by 2 desc;


-- 4. Top three countries with highest total amount of laid offs for 2020-2023 
-- US had 256,559, India had 35,993, and Netherlands had 17,220 laid offs.
select country, sum(total_laid_off)
from world_layoffs.layoffs_staging2
group by country
order by 2 desc;


-- 5. Total world laid offs by year:
-- 2020 = 80998, 2021 = 15823, 2022 = 160661, and 2023 = 125677.
select extract(year from "date"), sum(total_laid_off)
from world_layoffs.layoffs_staging2
group by extract(year from "date")
order by 1 desc;


-- 6. Total world laid offs by company stage.
select stage, sum(total_laid_off)
from world_layoffs.layoffs_staging2
group by stage
order by 1 desc;



-- 7. Rolling sum for total laid offs per month.
select substring("date"::text,1, 7) as "month", sum(total_laid_off)
from world_layoffs.layoffs_staging2
where substring("date"::text,1, 7) is not null
group by "month"
order by 1 asc;

with rolling_total_layoffs as
(
	select 
		substring("date"::text,1, 7) as "month", sum(total_laid_off) as total_off
		from world_layoffs.layoffs_staging2
		where substring("date"::text,1, 7) is not null
		group by "month"
		order by 1 asc
)
select "month", total_off, sum(total_off) over (order by "month") as rolling_total
from rolling_total_layoffs;


-- 8. Total laid offs by company.
select company, sum(total_laid_off) 
FROM world_layoffs.layoffs_staging2
group by company
having sum(total_laid_off) > 0
order by 2 desc;


-- 9. Total laid offs for each company per year.
select company, extract(year from "date") as years, sum(total_laid_off) 
FROM world_layoffs.layoffs_staging2
group by company, "years"
having sum(total_laid_off) > 0
order by 3 desc;


-- 10. Top 3 countries with highest total laid offs per year.
with company_year(company, years, total_laid_off) as
(
	select company, extract(year from "date") as years, sum(total_laid_off) 
	from world_layoffs.layoffs_staging2
	group by company, years
	having sum(total_laid_off) > 0
),
company_year_rank as (
	select company, years, total_laid_off, dense_rank() over(
		partition by years order by total_laid_off desc) as ranking
	from company_year
	where years is not null
)
select company, years, total_laid_off, ranking 
from company_year_rank
where ranking <= 3;


-- 11. Average num of people laid off for companies at different stages of development.
select
	company,
	avg(total_laid_off) as avg_people_laid_off,
	stage as company_stage
from world_layoffs.layoffs_staging2
group by
	stage,
	company
having
	avg(total_laid_off) is not null;


-- 12. Average percentage of layoffs by industry.
select 
	industry,
	round(avg(percentage_laid_off::decimal),2) as avg_percentage_laid_off
from
	world_layoffs.layoffs_staging2
group by
	industry
having
	avg(percentage_laid_off::decimal) is not null
	and industry is not null;

-- 13. Average number of layoffs for each stage of a company.
select 
	stage,
	round(avg(total_laid_off::decimal), 2) as avg_layoffs
from
	world_layoffs.layoffs_staging2
group by
	stage
having 
	avg(total_laid_off::decimal) is not null
	and stage is not null;


-- 14. Companies with highest funds raised per employee laid off.
select
	company,
	funds_raised_millions/total_laid_off as funds_per_emp
from
	world_layoffs.layoffs_staging2
where 
	funds_raised_millions/total_laid_off is not null
order by
	funds_per_emp desc
limit 5;


-- 15. Total number of layoffs for each month.
select
	to_char("date"::date, 'MM/YYYY') as "month",
	sum(total_laid_off) as total_layoffs
from
	world_layoffs.layoffs_staging2
group by
	to_char("date"::date, 'MM/YYYY')
order by
	to_char("date"::date, 'MM/YYYY');


-- 16. Average distribution of layoffs by location.
-- Top three locations include SF Bay Area, Seattle, and NYC.
select
	"location",
	sum(total_laid_off) as total_layoffs
from
	world_layoffs.layoffs_staging2
group by
	"location"
having
	"location" is not null
	and sum(total_laid_off) is not null
order by 
	total_layoffs desc;