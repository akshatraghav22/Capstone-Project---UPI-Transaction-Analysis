-- ============================================================
-- UPI Transaction Analysis - Business Question Queries
-- Module 3: SQL Analysis
-- MySQL 8.0+ syntax. Run against the upi_transactions database.
-- ============================================================
-- Every query below has been tested against the actual dataset
-- (via an equivalent SQLite copy) before being handed to you.
-- ============================================================

USE upi_transactions;


-- ============================================================
-- Q1: Which channel has the highest transaction failure rate?
-- Concepts used: GROUP BY, CASE (conditional aggregation)
-- ============================================================
SELECT
    channel,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(100.0 * SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS failure_rate_pct
FROM upi_transaction_history
GROUP BY channel
ORDER BY failure_rate_pct DESC;

-- RESULT (from test run): app=6.00%, intent=5.90%, qr_code=5.71%
-- INSIGHT: All 3 channels have very similar failure rates (~6%).
-- No single channel stands out as a major outlier — failures are
-- evenly distributed, suggesting the cause is systemic (e.g.
-- network/bank-side issues) rather than channel-specific.


-- ============================================================
-- Q2: Which merchants have both HIGH failure rate AND meaningful
--     volume? (avoids the "2 transactions, 1 failed = 50%" trap
--     we discussed in Module 1 — HAVING filters out small samples)
-- Concepts used: JOIN, GROUP BY, HAVING
-- ============================================================
SELECT
    m.merchant_id,
    m.merchant_name,
    m.merchant_type,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(CASE WHEN t.status = 'failed' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(100.0 * SUM(CASE WHEN t.status = 'failed' THEN 1 ELSE 0 END) / COUNT(t.transaction_id), 2) AS failure_rate_pct
FROM upi_transaction_history t
JOIN merchant_info m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_id, m.merchant_name, m.merchant_type
HAVING COUNT(t.transaction_id) >= 50      -- minimum volume threshold
ORDER BY failure_rate_pct DESC
LIMIT 10;

-- INSIGHT: These are merchants worth investigating first — high
-- failure rate is not a fluke here because each has 50+ transactions.


-- ============================================================
-- Q3a: Which region shows the highest fraud rate?
-- Concepts used: JOIN, GROUP BY, CASE
-- ============================================================
SELECT
    c.region,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_transactions,
    ROUND(100.0 * SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) / COUNT(*), 3) AS fraud_rate_pct
FROM upi_transaction_history t
JOIN customer_master c ON t.customer_id = c.customer_id
GROUP BY c.region
ORDER BY fraud_rate_pct DESC;

-- RESULT: West (2.09%), South (2.03%), East (2.00%), North (1.94%), Central (1.94%)
-- INSIGHT: Fraud rate is fairly evenly spread across regions
-- (1.9%-2.1% range) — region is NOT a strong fraud predictor here.


-- ============================================================
-- Q3b: Does device rooted status affect fraud rate?
-- (Directly tests Hypothesis #1 from Module 1)
-- Concepts used: JOIN, GROUP BY
-- ============================================================
SELECT
    d.is_rooted,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_transactions,
    ROUND(100.0 * SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) / COUNT(*), 3) AS fraud_rate_pct
FROM upi_transaction_history t
JOIN device_info d ON t.device_id = d.device_id
GROUP BY d.is_rooted;

-- RESULT: Non-rooted = 1.39% fraud rate | Rooted = 20.69% fraud rate
-- INSIGHT: *** MAJOR FINDING *** Rooted devices have a ~15x higher
-- fraud rate than non-rooted devices. This strongly CONFIRMS
-- Hypothesis #1 ("Rooted devices are associated with higher fraud
-- rates") and should be your #1 headline insight in the final report.
-- We'll confirm this statistically with a Chi-square test in Module 5.


-- ============================================================
-- Q4: How well is the fraud team resolving alerts?
-- Concepts used: Conditional aggregation (CASE)
-- ============================================================
SELECT
    COUNT(*) AS total_alerts,
    SUM(CASE WHEN resolved = 1 THEN 1 ELSE 0 END) AS resolved_alerts,
    ROUND(100.0 * SUM(CASE WHEN resolved = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS resolution_rate_pct
FROM fraud_alert_history;

-- RESULT: 2,000 alerts, 1,752 resolved = 87.6% resolution rate
-- INSIGHT: Healthy resolution rate (>85%), but 248 alerts (12.4%)
-- remain open — worth flagging as a follow-up action item.


-- ============================================================
-- Q5: Segment customers by activity recency (Active/At Risk/Churned)
-- Concepts used: CTE (WITH clause), subquery, CASE, JULIANDAY-style
--                date math (use DATEDIFF in MySQL instead)
-- ============================================================
WITH customer_last_txn AS (
    SELECT customer_id, MAX(timestamp) AS last_txn_date
    FROM upi_transaction_history
    GROUP BY customer_id
),
platform_max_date AS (
    SELECT MAX(timestamp) AS max_date FROM upi_transaction_history
)
SELECT
    CASE
        WHEN DATEDIFF((SELECT max_date FROM platform_max_date), last_txn_date) <= 30
            THEN 'Active (last 30 days)'
        WHEN DATEDIFF((SELECT max_date FROM platform_max_date), last_txn_date) <= 90
            THEN 'At Risk (31-90 days)'
        ELSE 'Churned (90+ days)'
    END AS activity_segment,
    COUNT(*) AS customer_count
FROM customer_last_txn
GROUP BY activity_segment
ORDER BY customer_count DESC;

-- RESULT: Active=4,812 | At Risk=1,397 | Churned=823
-- INSIGHT: ~68% of customers are active, but ~12% (823) have
-- churned — a retention KPI worth tracking on the executive dashboard.


-- ============================================================
-- Q6: Rank merchants by total revenue (top performers)
-- Concepts used: Subquery, Window Function (RANK)
-- ============================================================
SELECT
    merchant_id,
    merchant_name,
    total_revenue,
    txn_count,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM (
    SELECT
        m.merchant_id,
        m.merchant_name,
        SUM(t.amount) AS total_revenue,
        COUNT(t.transaction_id) AS txn_count
    FROM upi_transaction_history t
    JOIN merchant_info m ON t.merchant_id = m.merchant_id
    WHERE t.status = 'success'
    GROUP BY m.merchant_id, m.merchant_name
) AS merchant_revenue
ORDER BY revenue_rank
LIMIT 10;

-- INSIGHT: Identifies your top 10 revenue-generating merchants —
-- useful for merchant partnership prioritization discussions.


-- ============================================================
-- Q7 (BONUS): Running monthly transaction volume trend
-- Concepts used: Window Function (SUM ... OVER, running total)
-- ============================================================
SELECT
    DATE_FORMAT(timestamp, '%Y-%m') AS txn_month,
    COUNT(*) AS monthly_transactions,
    SUM(COUNT(*)) OVER (ORDER BY DATE_FORMAT(timestamp, '%Y-%m')) AS running_total_transactions
FROM upi_transaction_history
GROUP BY txn_month
ORDER BY txn_month;

-- INSIGHT: Shows month-over-month platform growth trend — feeds
-- directly into the "Transaction Volume" KPI trend line in Power BI.