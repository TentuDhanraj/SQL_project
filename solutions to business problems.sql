-- 1. COUNT THE NUMBER OF MOVIES VS TV SHOWS
SELECT * FROM netflix;

SELECT type,
	COUNT(*)
FROM netflix
GROUP BY type;

-- 2. Find the most common rating for Movies and TV shows
/*
SELECT 
	type,
	rating
FROM
	(SELECT 
		type,
		rating,
		COUNT(*),
		RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) AS raNKING
	FROM netflix 
	GROUP BY 1, 2) AS t1
WHERE RANKing = 1; */

WITH rating_counts AS (
	SELECT 
		type,
		rating,
		count(*) AS rating_count
	FROM netflix
	GROUP BY type,rating
),

 ranked_rating AS (
	SELECT 
		type,
		rating,
		rating_count,		
		RANK() OVER(PARTITION BY type ORDER BY rating_count DESC) AS rank
	FROM rating_counts
)
SELECT 
	type,
	rating AS most_frequent_rating
FROM ranked_rating
WHERE rank=1;

-- 3. List all movies released in a specific year
SELECT title 
FROM netflix
	WHERE 
	type = 'Movie'
	AND
		release_year = 2001;
-- 4 Find the top 5 counries with most content on netflix
SELECT * FROM netflix 

SELECT 
	UNNEST(STRING_TO_ARRAY(country,',')) AS countries,
	COUNT(type) AS total_count
FROM netflix
GROUP BY 1
ORDER BY total_count DESC
LIMIT 5;

-- 5. Identify the Longest Movie
SELECT 
	type,
	duration
FROM netflix
WHERE type = 'Movie'
GROUP BY 1,2
ORDER BY duration DESC;

-- OR
SELECT 
	duration
FROM netflix
WHERE 
	type = 'Movie'
AND
	duration = (SELECT MAX(duration) FROM netflix);

-- 6. Find the content added in the last 5 years
SELECT 
	*
FROM netflix
WHERE 
	TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 Years';

-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!

SELECT
	*
FROM
	(
	SELECT
		*, 
		UNNEST(STRING_TO_ARRAY(director,',')) AS new_directors
	FROM 
		netflix
		) 	
WHERE new_directors = 'Rajiv Chilaka';

-- 8. List all TV shows with more than 5 seasons

SELECT *
FROM
	(SELECT
		*,
		SPLIT_PART(duration,' ',1) :: int AS tv_season
	FROM netflix)
WHERE 
	type = 'TV Show'
AND
	tv_season >5;

-- 9. Count the number of content items in each genre

SELECT
	UNNEST(STRING_TO_ARRAY(listed_in,',')) AS genre,
	COUNT(show_id) as total_content
FROM netflix
GROUP BY 1
ORDER BY 2 DESC;

-- 10. Find each year and the average numbers of content release by India on netflix. 
-- return top 5 year with highest avg content release !

SELECT 
	country,
	EXTRACT(YEAR FROM TO_DATE(date_added,'Month DD, YYYY')) AS year,
	COUNT(show_id) AS total_count,
	ROUND
		(
			100 * COUNT(show_id) :: numeric / (SELECT COUNT(show_id) FROM netflix WHERE country='India') :: numeric,
			2
		) as avg_release_per_year
FROM 
	netflix
WHERE 
	country = 'India'
GROUP BY 1,2;

-- 11. List all movies that are documentaries

SELECT * FROM netflix
WHERE 
	listed_in ILIKE '%documentaries%';

-- 12. Find all content without a director

SELECT * FROM netflix
WHERE
	director IS NULL;

-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT * FROM netflix
WHERE 
	casts ILIKE '%Salman Khan%'
AND
	release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;

-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

SELECT 
	UNNEST(STRING_TO_ARRAY(casts,',')) AS actor,
	COUNT(show_id) AS total_movies
FROM netflix
WHERE country='India'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

/*
Question 15:
Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.
*/

WITH new_table
AS
	(SELECT 
		*,
		CASE
			WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
			ELSE 'Good'
		END  AS category
	FROM netflix)
	
SELECT 
	category,
	COUNT(*) AS total_count
FROM new_table
GROUP BY 1;

-- END OF REPORTS