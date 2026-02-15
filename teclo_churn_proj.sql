SELECT * FROM telco_raw;

/* total customers by plan */
SELECT 
	contract,
	COUNT(customer_id) AS number_of_customers
FROM telco_raw
GROUP BY contract
ORDER BY contract DESC;

/* Avg Monthly Revenue */

SELECT
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_revenue_per_customer
FROM telco_raw;

/* Churn Rate */
SELECT churn, COUNT(*)
FROM telco_raw
GROUP BY churn;
SELECT 
	ROUND (
		100 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(customer_id),2
	) AS churn_rate
FROM 
	telco_raw;

/* Active vs Churned Users */
SELECT
    CASE 
        WHEN churn = 'No' THEN 'Active'
        ELSE 'Churned'
    END AS user_status,
    COUNT(*) AS user_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM telco_raw
GROUP BY user_status
ORDER BY user_count DESC;

/* Revenue By Tenure Bucket*/

SELECT * FROM telco_raw;
SELECT DISTINCT(tenure)
FROM telco_raw;
SELECT 
	CASE
		WHEN tenure <= 12 THEN '0-12 Months'
		WHEN tenure <= 24 THEN '13-24 Months'
		ELSE '24+ Months'
	END AS tenure_bucket,
COUNT (*) AS total_customers,
ROUND(
        SUM(NULLIF(TRIM(total_charges), '')::NUMERIC),
        2
    ) AS total_revenue

FROM telco_raw
GROUP BY tenure_bucket
ORDER BY total_revenue DESC;

/* High Risk Churn Segments */
SELECT 
	contract,
	SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
	ROUND( 100 *
		SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)/ COUNT(*),
		2
	) AS churned_rate
FROM telco_raw
GROUP BY contract
ORDER BY churned_rate DESC;

SELECT
    payment_method,

    COUNT(*) AS total_customers,

    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE churn = 'Yes')
        / COUNT(*),
        2
    ) AS churn_rate_pct

FROM telco_raw
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

SELECT
    internet_service,

    COUNT(*) AS total_customers,

    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE churn = 'Yes')
        / COUNT(*),
        2
    ) AS churn_rate_pct

FROM telco_raw
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;

SELECT
    CASE
        WHEN tenure <= 12 THEN '0-12 months'
        WHEN tenure <= 24 THEN '13-24 months'
        WHEN tenure <= 48 THEN '25-48 months'
        ELSE '49+ months'
    END AS tenure_bucket,

    COUNT(*) AS total_customers,

    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE churn = 'Yes')
        / COUNT(*),
        2
    ) AS churn_rate_pct

FROM telco_raw
GROUP BY tenure_bucket
ORDER BY churn_rate_pct DESC;

/* Monthly Cohort retention */ 
SELECT * FROM telco_raw;

WITH cohort_data AS (
	SELECT 
		customer_id,
		DATE_TRUNC(
			'month', 
			CURRENT_DATE - (tenure || ' months') ::interval
		) AS cohort_month,
		tenure
	FROM telco_raw
	),
	cohort_size AS (
	SELECT 
		cohort_month,
		COUNT(*) AS total_customers
	FROM cohort_data
	GROUP BY cohort_month
	),
	retention AS(
	SELECT 
		cohort_month,
		tenure AS months_since_join,
		COUNT(*) AS active_users
	FROM cohort_data
	GROUP BY cohort_month, tenure
	)
	SELECT
    r.cohort_month,
    r.months_since_join,
    r.active_users,
    cs.total_customers,
    ROUND(
        100.0 * r.active_users / cs.total_customers,
        2
    ) AS retention_rate_pct
FROM retention r
JOIN cohort_size cs
    ON r.cohort_month = cs.cohort_month
ORDER BY r.cohort_month, r.months_since_join;
	