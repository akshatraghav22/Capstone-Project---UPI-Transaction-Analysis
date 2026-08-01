## 📈 1. Core KPIs & Operational Metrics (Queries 1–6)

### Query 1: Total Transaction Volume & Value (TTV)
##  **Business Objective:** Quantify the scale of transactions processed on our UPI network.
 #  **SQL Code:**
    
    SELECT 
        COUNT(transaction_id) AS total_transaction_volume,
        ROUND(SUM(amount), 2) AS total_transaction_value
    FROM upi_transaction_history;
  
#  **Explanation:** Counts all records and sums transaction amounts to calculate TTV.
#   **Business Insight:** Represents the baseline volume and monetary throughput. In a growing FinTech, TTV is a primary valuation and size metric.

### Query 2: Transaction Success Rate (TSR)
#   **Business Objective:** Measure the operational health and reliability of the payment platform.

    SELECT 
        COUNT(CASE WHEN status = 'success' THEN 1 END) AS successful_transactions,
        COUNT(transaction_id) AS total_transactions,
        ROUND(COUNT(CASE WHEN status = 'success' THEN 1 END) * 100.0 / COUNT(transaction_id), 2) AS success_rate_pct
    FROM upi_transaction_history;

#   **Explanation:** Uses conditional aggregation (`CASE WHEN`) to calculate the percentage of transactions that completed successfully.
#   **Business Insight:** A success rate of 92.14% indicates that 7.86% of transactions fail or remain pending. This causes customer friction and needs technical auditing.

### Query 3: Average Transaction Value (ATV)
#  **Business Objective:** Understand the typical spend per transaction for successful transfers.

    SELECT 
        ROUND(AVG(amount), 2) AS avg_transaction_value
    FROM upi_transaction_history
    WHERE status = 'success';
   
#   **Explanation:** Calculates the arithmetic mean of amounts for success status rows.
#   **Business Insight:** An ATV of 42.38 suggests that UPI is primarily used for micro-transactions (grocery, snacks, small peer-to-peer transfers) rather than large ticket purchases.

### Query 4: Fraud Rate by Volume
#  **Business Objective:** Quantify the portion of transaction volume flagged as fraudulent.

    SELECT 
        COUNT(CASE WHEN fraud_flag = 1 THEN 1 END) AS fraud_transactions,
        COUNT(transaction_id) AS total_transactions,
        ROUND(COUNT(CASE WHEN fraud_flag = 1 THEN 1 END) * 100.0 / COUNT(transaction_id), 2) AS fraud_rate_vol_pct
    FROM upi_transaction_history;
   
#  **Explanation:** Divides the number of fraudulent records by total transactions.
#   **Business Insight:** A fraud rate of 2.00% by volume is higher than standard industry benchmarks (typically < 0.5%). This requires security controls.

### Query 5: Fraud Rate by Value (TTV at Risk)
#   **Business Objective:** Assess the financial loss from fraudulent transactions.

    SELECT 
        ROUND(SUM(CASE WHEN fraud_flag = 1 THEN amount ELSE 0 END), 2) AS fraud_value,
        ROUND(SUM(amount), 2) AS total_value,
        ROUND(SUM(CASE WHEN fraud_flag = 1 THEN amount ELSE 0 END) * 100.0 / SUM(amount), 4) AS fraud_rate_val_pct
    FROM upi_transaction_history;

#   **Explanation:** Computes fraud value divided by total TTV.
#   **Business Insight:** The fraud rate by value (1.9971%) matches the volume fraud rate, indicating that fraudsters are not disproportionately targeting higher value transactions, but rather committing fraud uniformly.

### Query 6: Reversal Success Rate
#   **Business Objective:** Measure the efficiency of returning funds to customers after transaction failures.

    SELECT 
        COUNT(CASE WHEN reversal_flag = 1 THEN 1 END) AS reversals_triggered,
        COUNT(CASE WHEN reversal_flag = 1 AND status = 'success' THEN 1 END) AS reversals_completed,
        ROUND(
            COUNT(CASE WHEN reversal_flag = 1 AND status = 'success' THEN 1 END) * 100.0 
            / NULLIF(COUNT(CASE WHEN reversal_flag = 1 THEN 1 END), 0), 
            2
        ) AS reversal_success_rate_pct
    FROM upi_transaction_history;
    
#  **Explanation:** Calculates the percentage of transactions marked for reversal that ultimately completed. `NULLIF` prevents division-by-zero errors.
#   **Business Insight:** **A major operational issue found!** The reversal success rate is 0.00% across 1,451 attempts. Reversal processing appears completely broken, which could lead to merchant disputes and poor customer retention.


## 👥 2. Customer Profiling & Behavioral Segmentations (Queries 7–14)

### Query 7: Active Customer Count
#   **Business Objective:** Determine the count of unique customers transacting on our platform.

    SELECT COUNT(DISTINCT customer_id) AS active_customers
    FROM upi_transaction_history;
  
#  **Explanation:** Counts unique customer IDs that appear in the transaction table.
#   **Business Insight:** 100% of registered customers have completed at least one transaction, showing high user adoption.

### Query 8: Average Transactions per Customer
#   **Business Objective:** Measure transaction frequency to assess customer engagement.

    SELECT 
        ROUND(COUNT(transaction_id) * 1.0 / COUNT(DISTINCT customer_id), 2) AS avg_txns_per_cust
    FROM upi_transaction_history;
   
#   **Explanation:** Divides total transactions by distinct customer count.
#  **Business Insight:** Customers average 10 transactions in this period, suggesting a regular usage habit.

### Query 9: Spending Distribution by Customer Age Group
#  **Business Objective:** Target marketing campaigns based on age-based spending habits.

    SELECT 
        CASE 
            WHEN age < 25 THEN 'Under 25 (Gen Z)'
            WHEN age BETWEEN 25 AND 40 THEN '25-40 (Millennials)'
            WHEN age BETWEEN 41 AND 55 THEN '41-55 (Gen X)'
            ELSE 'Over 55 (Boomers)'
        END AS age_group,
        COUNT(t.transaction_id) AS txn_count,
        ROUND(SUM(t.amount), 2) AS total_spend,
        ROUND(AVG(t.amount), 2) AS avg_spend
    FROM upi_transaction_history t
    JOIN customer_master c ON t.customer_id = c.customer_id
    WHERE t.status = 'success'
    GROUP BY age_group
    ORDER BY total_spend DESC;
    
#   **Explanation:** Segments users into age buckets, joins tables, filters for successful transactions, and groups metrics by age group.
#   **Business Insight:** Millennials are the highest overall spending group due to volume. However, the average spending per transaction is consistent across all age groups (approx. 42.30 - 42.70).

### Query 10: Top 10 Spending Customers
#   **Business Objective:** Identify high-value customers for premium benefits.

    SELECT 
        c.customer_id,
        c.full_name,
        c.region,
        COUNT(t.transaction_id) AS successful_txns,
        ROUND(SUM(t.amount), 2) AS total_spend
    FROM upi_transaction_history t
    JOIN customer_master c ON t.customer_id = c.customer_id
    WHERE t.status = 'success'
    GROUP BY c.customer_id, c.full_name, c.region
    ORDER BY total_spend DESC
    LIMIT 10;

#  **Explanation:** Aggregates transaction count and sum values, sorting descending by total spend, and limits output to the top 10.
#   **Business Insight:** Our top spenders transacted over 40 times and spent more than 2,000 INR each. We can target this segment with loyalty offers.

### Query 11: Customer Segmentations by Spending Volume (Low, Medium, High)
#   **Business Objective:** Segment the customer base into loyalty tiers.

    WITH customer_spend AS (
        SELECT customer_id, SUM(amount) AS total_spend
        FROM upi_transaction_history
        WHERE status = 'success'
        GROUP BY customer_id
    )
    SELECT 
        CASE 
            WHEN total_spend < 100 THEN 'Bronze (Low Spend < 100)'
            WHEN total_spend BETWEEN 100 AND 1000 THEN 'Silver (Medium Spend 100-1000)'
            ELSE 'Gold (High Spend > 1000)'
        END AS loyalty_tier,
        COUNT(customer_id) AS customer_count,
        ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM customer_master), 2) AS pct_of_customers
    FROM customer_spend
    GROUP BY loyalty_tier
    ORDER BY customer_count DESC;
 
#   **Explanation:** Uses a CTE to compute total spend per customer, then classifies them into Bronze, Silver, and Gold tiers.
#  **Business Insight:** The majority (88.29%) of our transacting customers are in the Silver tier. Only 10.21% are Gold spenders (spending over 1000 INR total). This indicates opportunities to drive customer engagement.

### Query 12: Customer Region Performance by Transaction Value
#  **Business Objective:** Identify geographical regions driving transactions.

    SELECT 
        c.region,
        COUNT(t.transaction_id) AS total_txns,
        ROUND(SUM(t.amount), 2) AS total_value,
        ROUND(SUM(t.amount) * 100.0 / (SELECT SUM(amount) FROM upi_transaction_history WHERE status = 'success'), 2) AS value_share_pct
    FROM upi_transaction_history t
    JOIN customer_master c ON t.customer_id = c.customer_id
    WHERE t.status = 'success'
    GROUP BY c.region
    ORDER BY total_value DESC;
   
#  **Explanation:** Joins customer regional metadata, aggregates volume and value, and computes regional share percentage.
#   **Business Insight:** Spending is distributed evenly across North, West, East, and South, each contributing 21–22% of total transaction value. The Central region has the lowest contribution (12.96%).

### Query 13: Average Risk Score of Customers by Region
#   **Business Objective:** Track regional risk profiles to manage fraud exposure.

    SELECT 
        region,
        ROUND(AVG(risk_score), 4) AS avg_risk_score,
        MAX(risk_score) AS max_risk_score
    FROM customer_master
    GROUP BY region
    ORDER BY avg_risk_score DESC;
  
#   **Explanation:** Computes average and maximum risk scores grouped by customer region.
#   **Business Insight:** Risk profiles are consistent across all regions (avg score 0.23–0.24, max score 0.68). This suggests that risk is distributed uniformly across our customer segments.

### Query 14: Cohort Retention (Monthly Sign-ups and Activity)
*   **Business Objective:** Measure customer retention by tracking sign-up cohorts.

    WITH cohort_users AS (
        SELECT 
            SUBSTR(date_joined, 1, 7) AS cohort_month,
            COUNT(customer_id) AS cohort_size
        FROM customer_master
        GROUP BY cohort_month
    ),
    active_cohort_users AS (
        SELECT 
            SUBSTR(c.date_joined, 1, 7) AS cohort_month,
            COUNT(DISTINCT t.customer_id) AS active_cohort_size
        FROM upi_transaction_history t
        JOIN customer_master c ON t.customer_id = c.customer_id
        GROUP BY cohort_month
    )
    SELECT 
        cu.cohort_month,
        cu.cohort_size,
        acu.active_cohort_size,
        ROUND(acu.active_cohort_size * 100.0 / cu.cohort_size, 2) AS retention_rate_pct
    FROM cohort_users cu
    JOIN active_cohort_users acu ON cu.cohort_month = acu.cohort_month
    ORDER BY cu.cohort_month;
 
#   **Explanation:** Uses CTEs to calculate cohort registration sizes and distinct active transacting users, then joins them to compute retention.
#   **Business Insight:** 100% of users in each signup cohort have initiated at least one transaction, indicating that onboarding effectively converts signups into active transacting users.

---

## 🏬 3. Merchant Performance & Category Share (Queries 15–22)

### Query 15: Top 10 Merchants by Total Sales Value
#   **Business Objective:** Identify major merchant accounts to build B2B relationships.

    SELECT 
        m.merchant_id,
        m.merchant_name,
        m.merchant_type,
        COUNT(t.transaction_id) AS total_sales_volume,
        ROUND(SUM(t.amount), 2) AS total_sales_value
    FROM upi_transaction_history t
    JOIN merchant_info m ON t.merchant_id = m.merchant_id
    WHERE t.status = 'success'
    GROUP BY m.merchant_id, m.merchant_name, m.merchant_type
    ORDER BY total_sales_value DESC
    LIMIT 10;

#   **Explanation:** Aggregates transaction counts and sum values, grouping by merchant details, filtered for successful payments.
#   **Business Insight:** These top 10 merchants drive high volume and value on our platform. We can offer them lower transaction fees (MDR) to maintain volume.

### Query 16: Transaction Success Rate by Merchant Type
#   **Business Objective:** Identify if specific merchant categories experience high payment failure rates.

    SELECT 
        m.merchant_type,
        COUNT(t.transaction_id) AS total_attempts,
        COUNT(CASE WHEN t.status = 'success' THEN 1 END) AS successful_txns,
        ROUND(COUNT(CASE WHEN t.status = 'success' THEN 1 END) * 100.0 / COUNT(t.transaction_id), 2) AS success_rate_pct
    FROM upi_transaction_history t
    JOIN merchant_info m ON t.merchant_id = m.merchant_id
    GROUP BY m.merchant_type
    ORDER BY success_rate_pct DESC;
 
#   **Explanation:** Calculates success rate percentages grouped by merchant category.
#   **Business Insight:** Success rates are consistent across all categories at 91.8% to 92.7%. There are no major category-specific failures, indicating uniform gateway performance.

### Query 17: Average Risk Score of Merchants by Category
#   **Business Objective:** Identify merchant sectors that carry higher operational risk.

    SELECT 
        merchant_type,
        ROUND(AVG(risk_score), 4) AS avg_risk_score,
        MAX(risk_score) AS max_risk_score,
        COUNT(merchant_id) AS merchant_count
    FROM merchant_info
    GROUP BY merchant_type
    ORDER BY avg_risk_score DESC;
   
#   **Explanation:** Calculates statistical risk metrics grouped by merchant type.

#   **Business Insight:** Transport and Food merchants exhibit the highest average risk scores, which could point to chargeback rates or disputes in these industries.

### Query 18: Total Transaction Volume and Sales Value by Region for Merchants
#   **Business Objective:** Identify geographic demand zones for merchant acquisition.

    SELECT 
        m.region AS merchant_region,
        COUNT(t.transaction_id) AS total_sales_count,
        ROUND(SUM(t.amount), 2) AS total_sales_value
    FROM upi_transaction_history t
    JOIN merchant_info m ON t.merchant_id = m.merchant_id
    WHERE t.status = 'success'
    GROUP BY m.region
    ORDER BY total_sales_value DESC;
   
#   **Explanation:** Joins transaction and merchant tables, aggregates values, and groups by merchant region.
#   **Business Insight:** Merchant sales match customer distribution, with North and West leading and Central having the lowest volume. This confirms aligned demand and supply across regions.

### Query 19: High-Risk Merchants and their Transaction Volumes
#   **Business Objective:** Identify merchants with high risk profiles (risk score > 0.40) to monitor chargebacks.

    SELECT 
        m.merchant_id,
        m.merchant_name,
        m.merchant_type,
        m.risk_score,
        COUNT(t.transaction_id) AS transaction_attempts,
        COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) AS fraud_alerts_triggered
    FROM merchant_info m
    LEFT JOIN upi_transaction_history t ON m.merchant_id = t.merchant_id
    WHERE m.risk_score > 0.40
    GROUP BY m.merchant_id, m.merchant_name, m.merchant_type, m.risk_score
    ORDER BY m.risk_score DESC, transaction_attempts DESC;
   
#   **Explanation:** Filters for merchants with risk scores above 0.40, aggregates total transactions and fraud counts, and lists them sorted by risk.
#   **Business Insight:** Identifies specific high-risk merchants with high fraud alert counts. We can flag these merchants for manual compliance reviews.

### Query 20: Merchant Type Spending Breakdown
#  **Business Objective:** Identify the merchant categories driving transaction volume.

    SELECT 
        m.merchant_type,
        COUNT(t.transaction_id) AS successful_transactions,
        ROUND(SUM(t.amount), 2) AS total_value_processed,
        ROUND(SUM(t.amount) * 100.0 / (SELECT SUM(amount) FROM upi_transaction_history WHERE status = 'success' AND merchant_id IS NOT NULL), 2) AS category_share_pct
    FROM upi_transaction_history t
    JOIN merchant_info m ON t.merchant_id = m.merchant_id
    WHERE t.status = 'success'
    GROUP BY m.merchant_type
    ORDER BY total_value_processed DESC;
 
#   **Explanation:** Calculates sales share percentages across different merchant categories.

#  **Business Insight:** Apparel and Electronics account for over 44% of merchant payment volume. Campaigns targeting Apparel promotions could capture higher transaction values.

### Query 21: Unique Customers per Merchant
#   **Business Objective:** Assess merchant customer bases to identify key partners.

    SELECT 
        m.merchant_id,
        m.merchant_name,
        m.merchant_type,
        COUNT(DISTINCT t.customer_id) AS unique_customers_served,
        COUNT(t.transaction_id) AS total_transactions,
        ROUND(COUNT(t.transaction_id) * 1.0 / COUNT(DISTINCT t.customer_id), 2) AS repeat_transaction_rate
    FROM upi_transaction_history t
    JOIN merchant_info m ON t.merchant_id = m.merchant_id
    WHERE t.status = 'success'
    GROUP BY m.merchant_id, m.merchant_name, m.merchant_type
    ORDER BY unique_customers_served DESC
    LIMIT 5;

#   **Explanation:** Counts unique customers and calculates transactions-per-customer ratios for merchants.
#   **Business Insight:** Top merchants serve around 100 unique customers, with a repeat rate of ~1.2. This suggests transactional patterns resemble one-time buys rather than high-frequency repeat purchases.

### Query 22: Merchant Revenue Month-on-Month Growth
#   **Business Objective:** Identify merchants exhibiting rapid growth.

WITH merchant_monthly AS (
    SELECT
        m.merchant_id,
        m.merchant_name,
        DATE_FORMAT(t.`timestamp`, '%Y-%m') AS ym,
        ROUND(SUM(t.amount), 2) AS sales
    FROM upi_transaction_history t
    JOIN merchant_info m
        ON t.merchant_id = m.merchant_id
    WHERE t.status = 'success'
    GROUP BY
        m.merchant_id,
        m.merchant_name,
        DATE_FORMAT(t.`timestamp`, '%Y-%m')
),
sales_growth AS (
    SELECT
        merchant_id,
        merchant_name,
        ym,
        sales,
        LAG(sales) OVER (
            PARTITION BY merchant_id
            ORDER BY ym
        ) AS prev_month_sales
    FROM merchant_monthly
)
SELECT
    merchant_id,
    merchant_name,
    ym,
    sales AS current_month_sales,
    prev_month_sales,
    ROUND(
        ((sales - prev_month_sales) * 100.0)
        / NULLIF(prev_month_sales, 0),
        2
    ) AS mom_growth_pct
FROM sales_growth
ORDER BY merchant_id, ym;

#   **Explanation:** Uses a CTE to aggregate sales, then applies the `LAG` window function partitioned by merchant ID to calculate growth rates.
#   **Business Insight:** Identifies which merchants are scaling up their sales volumes, allowing sales teams to cross-sell business-account features.



## 🛡️ 4. Fraud Risk, Device Profiling, & Threat Analysis (Queries 23–30)

### Query 23: Total Fraud Alerts by Alert Type
#   **Business Objective:** Identify the primary triggers for automated fraud alerts.

    SELECT 
        alert_type,
        COUNT(alert_id) AS alert_count,
        ROUND(COUNT(alert_id) * 100.0 / (SELECT COUNT(*) FROM fraud_alert_history), 2) AS contribution_pct
    FROM fraud_alert_history
    GROUP BY alert_type
    ORDER BY alert_count DESC;
 
#   **Explanation:** Group by alert category, counting alerts and calculating percentage contribution.
#   **Business Insight:** Alerts are spread across all categories, with "unusual transaction amount" and "frequent failures" leading. This highlights the need for dynamic fraud rules.

### Query 24: Fraud Rate by Device Type
#   **Business Objective:** Assess transaction risk based on user device category.

    SELECT 
        device_type,
        COUNT(transaction_id) AS total_txns,
        COUNT(CASE WHEN fraud_flag = 1 THEN 1 END) AS fraud_txns,
        ROUND(COUNT(CASE WHEN fraud_flag = 1 THEN 1 END) * 100.0 / COUNT(transaction_id), 4) AS fraud_rate_pct
    FROM upi_transaction_history
    GROUP BY device_type
    ORDER BY fraud_rate_pct DESC;
  
#   **Explanation:** Aggregates total transactions and fraud flags grouped by device type.
#   **Business Insight:** Feature phones exhibit the highest fraud rate (2.15%), while iOS exhibits the lowest (1.86%). Feature phones may be more vulnerable due to lack of biometric security options.

### Query 25: Rooted Device Fraud Risk
#   **Business Objective:** Check if rooted devices present a high risk of fraudulent activity.

    SELECT 
        d.is_rooted,
        COUNT(t.transaction_id) AS total_txns,
        COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) AS fraud_txns,
        ROUND(COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) * 100.0 / COUNT(t.transaction_id), 4) AS fraud_rate_pct
    FROM upi_transaction_history t
    JOIN device_info d ON t.device_id = d.device_id
    GROUP BY d.is_rooted;
 
#   **Explanation:** Joins device data, grouping metrics by the boolean `is_rooted` attribute.
#   **Business Insight:** **A major fraud indicator!** Transactions from rooted devices have a **20.69% fraud rate**—nearly 15 times higher than non-rooted devices (1.39%). Rooted devices allow system-level overrides, making them target vectors. We should block high-risk transaction types on rooted devices.

### Query 26: Top 10 High-Risk Customer Accounts
#   **Business Objective:** Identify customer accounts with multiple fraud alerts.

    SELECT 
        c.customer_id,
        c.full_name,
        c.risk_score AS customer_master_risk_score,
        COUNT(f.alert_id) AS fraud_alerts_triggered,
        COUNT(CASE WHEN f.resolved = 1 THEN 1 END) AS alerts_resolved
    FROM fraud_alert_history f
    JOIN upi_transaction_history t ON f.transaction_id = t.transaction_id
    JOIN customer_master c ON t.customer_id = c.customer_id
    GROUP BY c.customer_id, c.full_name, c.risk_score
    ORDER BY fraud_alerts_triggered DESC
    LIMIT 10;
  
#   **Explanation:** Joins customer, transaction, and fraud alert tables to count alerts triggered per customer, sorted descending.

#   **Business Insight:** Accounts with multiple alerts need compliance intervention. If a customer triggers 3+ alerts without resolution, their profile should be restricted.

### Query 27: Average Resolution Time for Fraud Alerts
#   **Business Objective:** Measure operational efficiency in resolving fraud cases.

        SELECT 
            alert_type,
            COUNT(alert_id) AS resolved_alerts,
            ROUND(AVG(TIMESTAMPDIFF(HOUR, alert_date, resolution_date)), 2) AS avg_resolution_time_hours
        FROM fraud_alert_history
        WHERE resolved = 1
        GROUP BY alert_type;
       
 
     
#   **Explanation:** Uses date functions to compute the average time difference between `alert_date` and `resolution_date` for resolved cases.
#   **Business Insight:** Average resolution time is around 30 hours, meaning fraud alerts remain open for over a day. We should set SLAs to resolve critical alerts (e.g., suspicious logins) within 4 hours.

### Query 28: Fraud Alert Resolution Rate
#   **Business Objective:** Measure risk clearance capacity by tracking open alerts.

    SELECT 
        COUNT(alert_id) AS total_alerts,
        COUNT(CASE WHEN resolved = 1 THEN 1 END) AS resolved_alerts,
        COUNT(CASE WHEN resolved = 0 THEN 1 END) AS open_alerts,
        ROUND(COUNT(CASE WHEN resolved = 1 THEN 1 END) * 100.0 / COUNT(alert_id), 2) AS resolution_rate_pct
    FROM fraud_alert_history;

#   **Explanation:** Aggregates counts of total, resolved, and open alerts to calculate overall resolution rate.
#   **Business Insight:** 12.4% (248 alerts) remain open and unresolved. We need to allocate risk operations staff to clear the backlog and protect users.

### Query 29: Regional Fraud Heatmap
#   **Business Objective:** Identify geographical regions with high fraud rates.

    SELECT 
        c.region AS customer_region,
        COUNT(t.transaction_id) AS total_txns,
        COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) AS fraud_txns,
        ROUND(COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) * 100.0 / COUNT(t.transaction_id), 4) AS fraud_rate_pct
    FROM upi_transaction_history t
    JOIN customer_master c ON t.customer_id = c.customer_id
    GROUP BY c.region
    ORDER BY fraud_rate_pct DESC;
   
#   **Explanation:** Joins transaction history with customer demographics to calculate regional fraud rates.
#   **Business Insight:** Fraud rates are consistent across all customer regions at 1.93% to 2.03%. This suggests fraud actors are targeting users uniformly, without showing a strong geographical preference.

### Query 30: Suspicious Micro-Transactions
#   **Business Objective:** Identify potential card/account testing fraud patterns.

    SELECT 
        customer_id,
        SUBSTR(timestamp, 1, 13) AS hour_bucket, -- Group by hour
        COUNT(transaction_id) AS txn_count,
        ROUND(SUM(amount), 2) AS total_amount
    FROM upi_transaction_history
    WHERE amount < 10.00
    GROUP BY customer_id, hour_bucket
    HAVING txn_count >= 5
    ORDER BY txn_count DESC
    LIMIT 10;

#   **Explanation:** Groups transactions into hourly buckets using substring slicing. Filters for small amounts (<10 INR) and identifies customers with 5+ such transactions in an hour.
#   **Business Insight:** High frequencies of low-value transactions within a single hour can indicate automated card testing or script-based velocity attacks. We should implement rate limiting to block more than 5 transactions per minute.


## 🏦 5. Bank Health, Failure Reasons, & Channel Reliability (Queries 31–36)

### Query 31: Transaction Status Breakdown
#   **Business Objective:** Review transactional volume distribution across statuses.

    SELECT 
        status,
        COUNT(transaction_id) AS txn_count,
        ROUND(COUNT(transaction_id) * 100.0 / (SELECT COUNT(*) FROM upi_transaction_history), 2) AS pct_share
    FROM upi_transaction_history
    GROUP BY status;
   
#   **Explanation:** Counts and calculates percentage share for transaction status values.
#   **Business Insight:** Failed and pending transactions make up 7.86% of traffic. Minimizing failures is a primary goal for operational improvement.

### Query 32: Top Failure Reasons
#   **Business Objective:** Identify the primary causes of transaction failures.

    SELECT 
        failure_reason,
        COUNT(transaction_id) AS failure_count,
        ROUND(COUNT(transaction_id) * 100.0 / (SELECT COUNT(*) FROM upi_transaction_history WHERE status = 'failed'), 2) AS contribution_pct
    FROM upi_transaction_history
    WHERE status = 'failed'
    GROUP BY failure_reason
    ORDER BY failure_count DESC;

#   **Explanation:** Groups and ranks failure reasons for rows marked failed.
#   **Business Insight:** Failures are split evenly between **Customer Issues** (Incorrect PIN, Account Blocked - 50.5%) and **Technical Issues** (Network Error, Bank Down - 49.5%). Resolving technical issues requires working with partner banks, while customer issues can be reduced through UI improvements.

### Query 33: Bank Partner Success Rates
#   **Business Objective:** Assess the service quality of partner banks.

    SELECT 
        a.bank_name,
        COUNT(t.transaction_id) AS total_attempts,
        COUNT(CASE WHEN t.status = 'success' THEN 1 END) AS success_txns,
        ROUND(COUNT(CASE WHEN t.status = 'success' THEN 1 END) * 100.0 / COUNT(t.transaction_id), 2) AS success_rate_pct,
        COUNT(CASE WHEN t.status = 'failed' THEN 1 END) AS failed_txns,
        ROUND(COUNT(CASE WHEN t.status = 'failed' THEN 1 END) * 100.0 / COUNT(t.transaction_id), 2) AS failure_rate_pct
    FROM upi_transaction_history t
    JOIN upi_account_details a ON t.upi_id = a.upi_id
    GROUP BY a.bank_name
    ORDER BY success_rate_pct DESC;
 
#   **Explanation:** Joins transaction history with bank account metadata, calculating success rates grouped by bank.
#   **Business Insight:** Success rates are consistent across our 6 banking partners (all ~92%). No single bank shows unusually high failure rates, indicating stable connectivity.

### Query 34: Transaction Failures by Time of Day
#   **Business Objective:** Identify times of day with higher technical failure rates.

    SELECT 
        SUBSTR(timestamp, 12, 2) AS hour_of_day,
        COUNT(transaction_id) AS total_attempts,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) AS failed_attempts,
        ROUND(COUNT(CASE WHEN status = 'failed' THEN 1 END) * 100.0 / COUNT(transaction_id), 2) AS failure_rate_pct
    FROM upi_transaction_history
    GROUP BY hour_of_day
    ORDER BY hour_of_day;

#   **Explanation:** Extracts the hour from the timestamp string and calculates failure rates for each hourly bucket.
#   **Business Insight:** Helps identify if server maintenance windows or peak transaction hours correlate with higher failure rates.

### Query 35: Channel Performance
#   **Business Objective:** Identify the most reliable payment channel (App, Intent, QR Code).

    SELECT 
        channel,
        COUNT(transaction_id) AS total_attempts,
        COUNT(CASE WHEN status = 'success' THEN 1 END) AS successful_txns,
        ROUND(COUNT(CASE WHEN status = 'success' THEN 1 END) * 100.0 / COUNT(transaction_id), 2) AS success_rate_pct
    FROM upi_transaction_history
    GROUP BY channel
    ORDER BY success_rate_pct DESC;

#   **Explanation:** Groups attempts and success counts by payment channel.
#   **Business Insight:** Performance is consistent across all payment channels (~92%). This indicates that payment routing is stable across standard mobile interfaces.

### Query 36: Technical Failures vs Customer Failures
#   **Business Objective:** Distinguish between system issues and user errors.

    SELECT 
        CASE 
            WHEN failure_reason IN ('network_error', 'bank_down') THEN 'Technical Failure'
            WHEN failure_reason IN ('incorrect_pin', 'account_blocked') THEN 'Customer Error'
            ELSE 'Unknown/Other'
        END AS failure_type,
        COUNT(transaction_id) AS failure_count,
        ROUND(COUNT(transaction_id) * 100.0 / (SELECT COUNT(*) FROM upi_transaction_history WHERE status = 'failed'), 2) AS failure_pct
    FROM upi_transaction_history
    WHERE status = 'failed'
    GROUP BY failure_type;
  
#   **Explanation:** Classifies failure reasons into Technical Failures and Customer Errors.
#   **Business Insight:** Customer errors and technical failures contribute equally to total transaction failures. Reducing technical failures requires system upgrades, while reducing customer errors can be addressed with improved user notifications.

---

## 📈 6. Transaction Trends, Velocity, & Time-Series (Queries 37–42)

### Query 37: Daily Transaction Trends
#   **Business Objective:** Monitor transaction volume and value trends over time.

    SELECT 
        SUBSTR(timestamp, 1, 10) AS txn_date,
        COUNT(transaction_id) AS txn_volume,
        ROUND(SUM(amount), 2) AS total_ttv
    FROM upi_transaction_history
    WHERE status = 'success'
    GROUP BY txn_date
    ORDER BY txn_date DESC
    LIMIT 7; -- Show last 7 days
 
#  **Explanation:** Groups transactions by date and displays volume and value for recent records.
#  **Business Insight:** Tracks daily processing activity. Declining daily volumes could indicate service disruptions.

### Query 38: Peak Hours of Day by Transaction Volume
#   **Business Objective:** Identify peak usage hours to plan server capacity.

    SELECT 
        SUBSTR(timestamp, 12, 2) AS txn_hour,
        COUNT(transaction_id) AS txn_count,
        ROUND(SUM(amount), 2) AS total_value
    FROM upi_transaction_history
    WHERE status = 'success'
    GROUP BY txn_hour
    ORDER BY txn_count DESC;

#   **Explanation:** Extracts the hour component from transaction timestamps and ranks hours by transaction count.
#  **Business Insight:** Identifies peak hours to schedule system maintenance during low-activity windows (e.g., 2 AM - 4 AM) to minimize user disruption.

### Query 39: Weekend vs Weekday Spending Comparisons
#   **Business Objective:** Analyze if transaction behavior changes during weekends.

SELECT
    CASE
        WHEN DAYOFWEEK(`timestamp`) IN (1, 7)
        THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(transaction_id) AS txn_count,
    ROUND(SUM(amount), 2) AS total_value,
    ROUND(AVG(amount), 2) AS avg_txn_value
FROM upi_transaction_history
WHERE status = 'success'
GROUP BY
    CASE
        WHEN DAYOFWEEK(`timestamp`) IN (1, 7)
        THEN 'Weekend'
        ELSE 'Weekday'
    END;
 
#   **Explanation:** Uses date functions to classify timestamps as Weekdays or Weekends, then aggregates transaction metrics.
#   **Business Insight:** Average transaction values remain consistent at ~42.30 on both weekdays and weekends. Spending habits do not change significantly on weekends.

### Query 40: Average Velocity of Transactions
#   **Business Objective:** Calculate the typical frequency of transactions per customer.

  WITH next_txns AS (
    SELECT
        customer_id,
        `timestamp`,
        LEAD(`timestamp`) OVER (
            PARTITION BY customer_id
            ORDER BY `timestamp`
        ) AS next_timestamp
    FROM upi_transaction_history
    WHERE status = 'success'
)
SELECT
    COUNT(*) AS analyzed_transitions,
    ROUND(
        AVG(
            TIMESTAMPDIFF(HOUR, `timestamp`, next_timestamp)
        ),
        2
    ) AS avg_hours_between_txns
FROM next_txns
WHERE next_timestamp IS NOT NULL;
#   **Explanation:** Uses a CTE and the `LEAD` window function to calculate the time difference between a customer's consecutive successful transactions.
#   **Business Insight:** Customers average 182 hours (approx. 7.5 days) between successful transactions. Identifying segments with shorter transaction gaps can help target high-frequency users.

### Query 41: Average Transaction Amount by Payment Channel
#   **Business Objective:** Analyze if certain payment channels process higher transaction values.

    SELECT 
        channel,
        COUNT(transaction_id) AS txn_count,
        ROUND(SUM(amount), 2) AS total_amount,
        ROUND(AVG(amount), 2) AS avg_txn_amount
    FROM upi_transaction_history
    WHERE status = 'success'
    GROUP BY channel;

#   **Explanation:** Groups metrics by payment channel to analyze spending patterns.
#   **Business Insight:** Average values are consistent across channels. Payment channel choice is based on user convenience rather than purchase price.

### Query 42: Transaction Value Distribution (Bucketing)
#   **Business Objective:** Analyze transaction volumes across different amount ranges.

    SELECT 
        CASE 
            WHEN amount < 10 THEN '1. Micro-Spend (< 10)'
            WHEN amount BETWEEN 10 AND 50 THEN '2. Small Spend (10-50)'
            WHEN amount BETWEEN 50.01 AND 200 THEN '3. Medium Spend (50-200)'
            ELSE '4. Large Spend (> 200)'
        END AS amount_bucket,
        COUNT(transaction_id) AS txn_count,
        ROUND(COUNT(transaction_id) * 100.0 / (SELECT COUNT(*) FROM upi_transaction_history), 2) AS volume_pct
    FROM upi_transaction_history
    GROUP BY amount_bucket
    ORDER BY amount_bucket;

#   **Explanation:** Segments transactions into 4 amount ranges using conditional branching.
#   **Business Insight:** Over 70% of transactions are under 50 INR, while only 3.3% exceed 200 INR. This confirms UPI is primarily used for small, frequent daily purchases.


## 🚀 7. Advanced Window Functions, CTEs, Views, & Procedures (Queries 43–50)

### Query 43: Month-on-Month TTV Growth Rate
#   **Business Objective:** Measure the month-on-month growth rate of processing volume.

WITH monthly_ttv AS
(
    SELECT
        DATE_FORMAT(`timestamp`, '%Y-%m') AS ym,
        ROUND(SUM(amount),2) AS ttv
    FROM upi_transaction_history
    WHERE status='success'
    GROUP BY DATE_FORMAT(`timestamp`, '%Y-%m')
)

SELECT
    ym,
    ttv AS current_month_ttv,
    LAG(ttv) OVER(ORDER BY ym) AS prev_month_ttv,
    ROUND(
        ((ttv - LAG(ttv) OVER(ORDER BY ym))
        / NULLIF(LAG(ttv) OVER(ORDER BY ym),0))*100,
        2
    ) AS mom_growth_pct
FROM monthly_ttv
ORDER BY ym;

#   **Explanation:** Uses a CTE to calculate monthly sales, then applies `LAG` to compute growth rates relative to the previous month.
#   **Business Insight:** Highlights growth trends and seasonal variations. The platform shows consistent growth over the analyzed periods.

### Query 44: Running Total of Transactions by Customer
#   **Business Objective:** Calculate lifetime spend trajectories for active customers.

    SELECT 
        customer_id,
        timestamp,
        amount,
        ROUND(SUM(amount) OVER (PARTITION BY customer_id ORDER BY timestamp), 2) AS running_spend_total
    FROM upi_transaction_history
    WHERE status = 'success'
    ORDER BY customer_id, timestamp
    LIMIT 20;
 
#   **Explanation:** Applies `SUM` with a window clause partitioned by customer and ordered by timestamp to calculate a running total.
#   **Business Insight:** Helps identify when customers reach key spending milestones.

### Query 45: Customer Spending Rank within Region (Dense Rank)
#   **Business Objective:** Identify top-spending customers within each region.

    WITH ranked_cust AS (
        SELECT 
            c.region,
            c.customer_id,
            c.full_name,
            ROUND(SUM(t.amount), 2) AS total_spend,
            DENSE_RANK() OVER (PARTITION BY c.region ORDER BY SUM(t.amount) DESC) AS spend_rank
        FROM upi_transaction_history t
        JOIN customer_master c ON t.customer_id = c.customer_id
        WHERE t.status = 'success'
        GROUP BY c.region, c.customer_id, c.full_name
    )
    SELECT *
    FROM ranked_cust
    WHERE spend_rank <= 3;

#   **Explanation:** Groups spend by customer, applies `DENSE_RANK` partitioned by region, and filters for the top 3 ranks in each region.
#   **Business Insight:** Identifies the top 3 spending accounts in each region to target with localized high-value marketing campaigns.

### Query 46: Moving Average of Transaction Amount
#  **Business Objective:** Smooth out transaction fluctuations to analyze spending baselines.

    SELECT 
        customer_id,
        timestamp,
        amount,
        ROUND(AVG(amount) OVER (
            PARTITION BY customer_id 
            ORDER BY timestamp 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ), 2) AS moving_avg_5_txns
    FROM upi_transaction_history
    WHERE status = 'success'
    ORDER BY customer_id, timestamp
    LIMIT 20;

#   **Explanation:** Computes a 5-transaction moving average for each customer using the `ROWS BETWEEN` window clause.
#   **Business Insight:** Helps identify shifts in spending baselines, allowing marketing teams to detect changes in customer purchasing power.

### Query 47: Lead/Lag Analysis to Find Time Gaps
#   **Business Objective:** Identify customers with increasing intervals between transactions.

WITH time_gaps AS (
    SELECT
        customer_id,
        `timestamp`,
        LAG(`timestamp`, 1) OVER (
            PARTITION BY customer_id
            ORDER BY `timestamp`
        ) AS prev_timestamp
    FROM upi_transaction_history
    WHERE status = 'success'
)

SELECT
    customer_id,
    `timestamp`,
    prev_timestamp,
    ROUND(
        TIMESTAMPDIFF(
            SECOND,
            prev_timestamp,
            `timestamp`
        ) / 3600,
        2
    ) AS hours_since_last_txn
FROM time_gaps
WHERE prev_timestamp IS NOT NULL
ORDER BY hours_since_last_txn DESC
LIMIT 10;
  
#   **Explanation:** Uses `LAG` to get the previous timestamp, then calculates the time gap in hours.
#   **Business Insight:** Long gaps between transactions can indicate customer churn. These users can be targeted with re-engagement campaigns.

### Query 48: Create View - `daily_executive_metrics_summary`
#   **Business Objective:** Provide a unified view of operational KPIs for executive reporting.

CREATE OR REPLACE VIEW view_daily_executive_metrics AS
SELECT
    DATE(`timestamp`) AS txn_date,
    COUNT(*) AS total_attempts,

    SUM(
        CASE 
            WHEN status = 'success' THEN 1 
            ELSE 0 
        END
    ) AS success_count,

    ROUND(
        SUM(
            CASE 
                WHEN status = 'success' THEN 1 
                ELSE 0 
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS success_rate_pct,

    ROUND(
        SUM(
            CASE 
                WHEN status = 'success' THEN amount 
                ELSE 0 
            END
        ),
        2
    ) AS successful_ttv,

    SUM(
        CASE 
            WHEN fraud_flag = 1 THEN 1 
            ELSE 0 
        END
    ) AS fraud_alerts

FROM upi_transaction_history
GROUP BY DATE(`timestamp`);  

SELECT *
FROM view_daily_executive_metrics
ORDER BY txn_date;
#  **Explanation:** Creates a virtual table summarizing daily transactions, success rates, TTV, and fraud alerts.
#   **Business Insight:** Simplifies reporting by providing a pre-aggregated source for dashboards.

### Query 49: Create View - `high_risk_entities_blacklist`
#   **Business Objective:** Identify high-risk customers and merchants for monitoring.

CREATE OR REPLACE VIEW view_high_risk_entities_blacklist AS

SELECT
    'customer' AS entity_type,
    customer_id AS entity_id,
    full_name AS entity_name,
    risk_score
FROM customer_master
WHERE risk_score > 0.50

UNION ALL

SELECT
    'merchant' AS entity_type,
    merchant_id AS entity_id,
    merchant_name AS entity_name,
    risk_score
FROM merchant_info
WHERE risk_score > 0.40;

SELECT *
FROM view_high_risk_entities_blacklist
ORDER BY risk_score DESC;

#   **Explanation:** Combines high-risk customer and merchant records using `UNION ALL` to create a blacklist view.
#   **Business Insight:** Provides a centralized reference for transaction monitoring systems to audit high-risk transactions.

### Query 50: Database Index Performance Analysis
#   **Business Objective:** Verify that indexes are optimizing query performance.

EXPLAIN
SELECT *
FROM upi_transaction_history
WHERE customer_id = 'cust101660'
  AND `timestamp` >= '2025-01-01'
  AND `timestamp` < '2025-07-01';
  
  CREATE INDEX idx_customer_timestamp
ON upi_transaction_history (customer_id, `timestamp`);

SHOW INDEX FROM upi_transaction_history;
  
#   **Explanation:** Runs an `EXPLAIN` query to check the database execution plan and verify index usage.
#   **Business Insight:** The execution plan confirms that the query uses our defined secondary index `idx_trans_customer`, avoiding a full table scan and reducing execution time.
