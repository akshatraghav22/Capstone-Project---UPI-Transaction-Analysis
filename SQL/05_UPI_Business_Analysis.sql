
# -- Customer Analysis -- #


#Customer by Region
SELECT
region,
COUNT(*) AS customers
FROM customer_master
GROUP BY region
ORDER BY customers DESC;

# Customers by Gender
SELECT
gender,
COUNT(*) AS total
FROM customer_master
GROUP BY gender;

# Business vs Personal Users
SELECT
is_business_user,
COUNT(*) AS total_users
FROM customer_master
GROUP BY is_business_user;

# Average Risk Score
SELECT
ROUND(AVG(risk_score),2) AS avg_risk
FROM customer_master;

# Top 10 Highest Risk Customers
SELECT
customer_id,
full_name,
risk_score
FROM customer_master
ORDER BY risk_score DESC
LIMIT 10;

# Customer Age Distribution
SELECT
CASE
WHEN age <25 THEN 'Under 25'
WHEN age BETWEEN 25 AND 40 THEN '25-40'
WHEN age BETWEEN 41 AND 60 THEN '41-60'
ELSE '60+'
END AS age_group,
COUNT(*) AS customers
FROM customer_master
GROUP BY age_group;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------

# -- Transaction Analysis -- #


# Total Transaction Value
SELECT
SUM(amount) AS total_value
FROM upi_transaction_history;

# Average Transaction Amount
SELECT
ROUND(AVG(amount),2) AS average_amount
FROM upi_transaction_history;

# Maximum Transaction
SELECT
MAX(amount) AS highest_transaction
FROM upi_transaction_history;

# Minimum Transaction
SELECT
MIN(amount) AS lowest_transaction
FROM upi_transaction_history;

# Daily Transactions
SELECT
DATE(timestamp) AS transaction_date,
COUNT(*) AS total_transactions
FROM upi_transaction_history
GROUP BY DATE(timestamp)
ORDER BY transaction_date;

# Monthly Transactions
SELECT
MONTHNAME(timestamp) AS month_name,
COUNT(*) AS total_transactions
FROM upi_transaction_history
GROUP BY MONTH(timestamp), MONTHNAME(timestamp)
ORDER BY MONTH(timestamp);

# Transaction Status
SELECT
status,
COUNT(*) AS total
FROM upi_transaction_history
GROUP BY status;

# Success Rate
SELECT
ROUND(
SUM(CASE WHEN status='success' THEN 1 ELSE 0 END)
*100.0/
COUNT(*),2
) AS success_rate
FROM upi_transaction_history;

----------------------------------------------------------------------------------------------------------------------------------------------------------

# -- Mechant Analysis -- #

# Number of Merchants by Type
SELECT
    merchant_type,
    COUNT(*) AS total_merchants
FROM merchant_info
GROUP BY merchant_type
ORDER BY total_merchants DESC;

# Merchants by Region
SELECT
    region,
    COUNT(*) AS total_merchants
FROM merchant_info
GROUP BY region
ORDER BY total_merchants DESC;

# Top 10 Merchants by Transaction Count
SELECT
    m.merchant_name,
    COUNT(t.transaction_id) AS total_transactions
FROM merchant_info m
JOIN upi_transaction_history t
ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_name
ORDER BY total_transactions DESC
LIMIT 10;

# Top 10 Merchants by Revenue
SELECT
    m.merchant_name,
    ROUND(SUM(t.amount),2) AS total_revenue
FROM merchant_info m
JOIN upi_transaction_history t
ON m.merchant_id=t.merchant_id
WHERE t.status='Success'
GROUP BY m.merchant_name
ORDER BY total_revenue DESC
LIMIT 10;

# Average Transaction Amount by Merchant
SELECT
    m.merchant_name,
    ROUND(AVG(t.amount),2) AS average_transaction
FROM merchant_info m
JOIN upi_transaction_history t
ON m.merchant_id=t.merchant_id
GROUP BY m.merchant_name
ORDER BY average_transaction DESC;

#  High-Risk Merchants
SELECT
    merchant_name,
    risk_score
FROM merchant_info
ORDER BY risk_score DESC
LIMIT 10;

# Merchant Risk Category
SELECT
CASE
    WHEN risk_score>=0.8 THEN 'High Risk'
    WHEN risk_score>=0.5 THEN 'Medium Risk'
    ELSE 'Low Risk'
END AS risk_category,
COUNT(*) AS merchants
FROM merchant_info
GROUP BY risk_category;

# Merchant Success Rate
SELECT
    m.merchant_name,
    ROUND(
        SUM(CASE WHEN t.status='Success' THEN 1 ELSE 0 END)*100/COUNT(*),
        2
    ) AS success_rate
FROM merchant_info m
JOIN upi_transaction_history t
ON m.merchant_id=t.merchant_id
GROUP BY m.merchant_name
ORDER BY success_rate DESC;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

# -- Device Analysis -- #

# Devices by Type
SELECT
device_type,
COUNT(*) AS total_devices
FROM device_info
GROUP BY device_type; 

# Rooted vs Non-Rooted Devices
SELECT
is_rooted,
COUNT(*) AS total
FROM device_info
GROUP BY is_rooted;

# Transactions by Device Type 
SELECT
device_type,
COUNT(*) AS total_transactions
FROM upi_transaction_history
GROUP BY device_type;

# Fraud by Device Type
SELECT
device_type,
COUNT(*) AS fraud_transactions
FROM upi_transaction_history
WHERE fraud_flag=TRUE
GROUP BY device_type;

# Average Transaction by Device
SELECT
device_type,
ROUND(AVG(amount),2) AS avg_amount
FROM upi_transaction_history
GROUP BY device_type;

# Device Success Rate
SELECT
device_type,
ROUND(
SUM(CASE WHEN status='Success' THEN 1 ELSE 0 END)
*100/COUNT(*),2
) AS success_rate
FROM upi_transaction_history
GROUP BY device_type;

# Top Active Devices
SELECT
device_id,
COUNT(*) AS total_transactions
FROM upi_transaction_history
GROUP BY device_id
ORDER BY total_transactions DESC
LIMIT 10;

# App Version Distribution
SELECT
app_version,
COUNT(*) AS users
FROM device_info
GROUP BY app_version
ORDER BY users DESC;


------------------------------------------------------------------------------------------------------------------------------------------------------------------


# -- Fraud Analysis -- #

# Total Fraud Transactions
 SELECT
COUNT(*) AS fraud_transactions
FROM upi_transaction_history
WHERE fraud_flag=TRUE;

# Fraud Rate
SELECT
ROUND(
SUM(CASE WHEN fraud_flag=TRUE THEN 1 ELSE 0 END)
*100/COUNT(*),2
) AS fraud_rate
FROM upi_transaction_history;

# Fraud by Region
SELECT
c.region,
COUNT(*) AS fraud_cases
FROM upi_transaction_history t
JOIN customer_master c
ON t.customer_id=c.customer_id
WHERE fraud_flag=TRUE
GROUP BY c.region
ORDER BY fraud_cases DESC;

# Fraud by Merchant
SELECT
m.merchant_name,
COUNT(*) AS fraud_cases
FROM upi_transaction_history t
JOIN merchant_info m
ON t.merchant_id=m.merchant_id
WHERE fraud_flag=TRUE
GROUP BY m.merchant_name
ORDER BY fraud_cases DESC;

# Fraud by Device Type
SELECT
device_type,
COUNT(*) AS fraud_cases
FROM upi_transaction_history
WHERE fraud_flag=TRUE
GROUP BY device_type;

# Fraud by Channel
SELECT
channel,
COUNT(*) AS fraud_cases
FROM upi_transaction_history
WHERE fraud_flag=TRUE
GROUP BY channel
ORDER BY fraud_cases DESC;

# Fraud by Transaction Type
SELECT
transaction_type,
COUNT(*) AS fraud_cases
FROM upi_transaction_history
WHERE fraud_flag=TRUE
GROUP BY transaction_type;

# High-Risk Customers with Fraud
SELECT
c.customer_id,
c.full_name,
c.risk_score,
COUNT(*) AS fraud_cases
FROM customer_master c
JOIN upi_transaction_history t
ON c.customer_id=t.customer_id
WHERE fraud_flag=TRUE
GROUP BY c.customer_id,c.full_name,c.risk_score
ORDER BY fraud_cases DESC;

# Fraud Alert Resolution Status
SELECT
resolved,
COUNT(*) AS alerts
FROM fraud_alert_history
GROUP BY resolved;

# Average Resolution Time
SELECT
ROUND(
AVG(TIMESTAMPDIFF(HOUR,alert_date,resolution_date)),
2
) AS avg_resolution_hours
FROM fraud_alert_history
WHERE resolved=TRUE;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------


# -- Customer Feedback Analysis -- #

# Average Satisfaction Score
SELECT
ROUND(AVG(satisfaction_score),2) AS average_rating
FROM customer_feedback_surveys;

# Satisfaction Distribution
SELECT
satisfaction_score,
COUNT(*) AS customers
FROM customer_feedback_surveys
GROUP BY satisfaction_score
ORDER BY satisfaction_score;

# Issue Type Distribution
SELECT
issue_type,
COUNT(*) AS issues
FROM customer_feedback_surveys
GROUP BY issue_type
ORDER BY issues DESC;

# Resolved vs Unresolved Issues
SELECT
resolved,
COUNT(*) AS total
FROM customer_feedback_surveys
GROUP BY resolved;

# Satisfaction by Region
SELECT
c.region,
ROUND(AVG(f.satisfaction_score),2) AS avg_satisfaction
FROM customer_feedback_surveys f
JOIN customer_master c
ON f.customer_id=c.customer_id
GROUP BY c.region
ORDER BY avg_satisfaction DESC;

# Satisfaction by Customer Type
SELECT
c.is_business_user,
ROUND(AVG(f.satisfaction_score),2) AS avg_rating
FROM customer_feedback_surveys f
JOIN customer_master c
ON f.customer_id=c.customer_id
GROUP BY c.is_business_user;

# Most Common Unresolved Issues
SELECT
issue_type,
COUNT(*) AS pending_issues
FROM customer_feedback_surveys
WHERE resolved=FALSE
GROUP BY issue_type
ORDER BY pending_issues DESC;