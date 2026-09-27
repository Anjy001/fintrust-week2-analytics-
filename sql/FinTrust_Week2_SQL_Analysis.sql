-- =====================================================================
-- FinTrust_Week2_SQL_Analysis.sql
-- AnalystLab Africa Experience Lab | Week 2 | Data Analytics Track
-- Project: FinTrust Financial Intelligence & Digital Banking Support Solution
--
-- SOURCES (synthetic, educational):
--   FinTrust_Customer_Data.csv      (1,500 rows x 12 columns)
--   FinTrust_Transaction_Data.csv   (12,000 rows x 11 columns)
--   FinTrust_Data_Dictionary.xlsx   (12 field definitions)
--   Join key: Customer_ID  (1 customer : many transactions; 0 orphans)
--
-- ENGINE: written for SQLite / DuckDB; also runs on MySQL / PostgreSQL / SQL Server
--         with the noted date-function substitutions.
--
-- DATA DISCLAIMER: all FinTrust data is synthetic and for educational purposes.
-- Risk_Review_Flag is a synthetic educational label and is NOT a real fraud
-- determination or real banking risk decision.
--
-- FORMAT: each question gives Business Question -> SQL Query -> Result -> Business Interpretation
-- =====================================================================


-- =====================================================================
-- Q1. Which transaction channels carry the most activity and value?
-- =====================================================================
-- BUSINESS QUESTION:
--   How is transaction activity and value distributed across channels,
--   and which channel should FinTrust prioritise for investment?
--
-- SQL QUERY:
SELECT
    t.Channel,
    COUNT(*)                        AS transactions,
    SUM(t.Amount_NGN)               AS total_value_ngn,
    ROUND(AVG(t.Amount_NGN), 2)     AS avg_value_ngn,
    ROUND(100.0 * SUM(CASE WHEN t.Transaction_Status = 'Successful' THEN 1 ELSE 0 END)
          / COUNT(*), 2)            AS success_rate_pct
FROM FinTrust_Transaction_Data t
GROUP BY t.Channel
ORDER BY total_value_ngn DESC;

-- RESULT (5 rows):
--   Mobile App : 5,102 txns | NGN 240,104,365.19 | avg NGN 47,060.83 | 90.XX% success
--   POS        : 2,393 txns | NGN 104,346,681.23 | avg NGN 43,604.96
--   Web        : 1,869 txns | NGN  89,324,999.94 | avg NGN 47,792.94
--   ATM        : 1,747 txns | NGN  83,942,354.23 | avg NGN 48,049.43
--   USSD       :   889 txns | NGN  42,758,954.26 | avg NGN 48,097.81
--
-- BUSINESS INTERPRETATION:
--   Mobile App alone carries NGN 240.1m (42.8% of all transaction value) on the
--   largest transaction count, confirming it is FinTrust's primary channel and the
--   correct priority for reliability investment. POS is the clear second channel by
--   value. USSD, despite the smallest value, has the highest average transaction size
--   (NGN 48,098) — an efficient channel serving fewer, larger transactions, which
--   suggests it serves a distinct customer need rather than being redundant.


-- =====================================================================
-- Q2. Which transaction types concentrate value and risk?
-- =====================================================================
-- BUSINESS QUESTION:
--   Which transaction types generate the most value, and where should the
--   (synthetic) risk-review workload be concentrated?
--
-- SQL QUERY:
SELECT
    t.Transaction_Type,
    COUNT(*)                                        AS transactions,
    SUM(t.Amount_NGN)                               AS total_value_ngn,
    ROUND(AVG(t.Amount_NGN), 2)                     AS avg_value_ngn,
    SUM(CASE WHEN t.Risk_Review_Flag = 'Yes' THEN 1 ELSE 0 END) AS flagged_txns,
    ROUND(100.0 * SUM(CASE WHEN t.Risk_Review_Flag = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                            AS risk_review_rate_pct
FROM FinTrust_Transaction_Data t
GROUP BY t.Transaction_Type
ORDER BY risk_review_rate_pct DESC;

-- RESULT (6 rows, sorted by risk-review rate):
--   Transfer        : 3,549 txns | avg NGN 67,037.67 | 1,011 flagged | 28.49%
--   Cash Withdrawal : 1,430 txns | avg NGN 47,393.26 |   362 flagged | 25.31%
--   Deposit         : 1,328 txns | avg NGN 98,633.33 |   215 flagged | 16.19%
--   Airtime/Data    : 1,185 txns | avg NGN  8,249.93 |   180 flagged | 15.19%
--   Card Purchase   : 3,033 txns | avg NGN 28,309.73 |   395 flagged | 13.02%
--   Bill Payment    : 1,475 txns | avg NGN 19,094.00 |   189 flagged | 12.81%
--
-- BUSINESS INTERPRETATION:
--   Value and risk sit on different transaction types. Deposits carry the highest
--   average value (NGN 98,633) but a below-average risk-review rate (16.19%), while
--   Transfers carry the highest risk-review rate (28.49%) and the second-highest
--   average value (NGN 67,038). Transfer and Cash Withdrawal together account for
--   1,373 of the 2,352 flagged transactions (58%) on only 41% of volume — so a
--   review workflow targeted at these two types would cover most of the workload
--   while leaving fast, low-risk types such as Bill Payment and Card Purchase
--   straight-through. Airtime/Data is high-volume but very low value (NGN 8,250).


-- =====================================================================
-- Q3. What is the transaction success profile, and where does it fail?
-- =====================================================================
-- BUSINESS QUESTION:
--   What proportion of transactions succeed, and how does failure
--   concentrate across channels?
--
-- SQL QUERY:
SELECT
    t.Transaction_Status,
    COUNT(*)                        AS transactions,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM FinTrust_Transaction_Data), 2) AS share_pct,
    ROUND(SUM(t.Amount_NGN), 2)     AS total_value_ngn
FROM FinTrust_Transaction_Data t
GROUP BY t.Transaction_Status
ORDER BY transactions DESC;

-- RESULT (4 rows):
--   Successful : 10,856 txns | 90.47% | NGN 510,774,306.XX
--   Failed     :    630 txns |  5.25% | NGN  24,825,748.XX
--   Reversed   :    326 txns |  2.72% | NGN  15,628,181.XX
--   Pending    :    188 txns |  1.57% | NGN   9,221,822.XX
--
-- BUSINESS INTERPRETATION:
--   A 90.47% success rate is a healthy headline, but the 7.97% of transactions that
--   fail or reverse represent direct operational friction, support-desk volume and
--   refund handling. Channel-level follow-up (see Q4) is the actionable next step:
--   the headline number is acceptable, but it hides where the failures actually sit.


-- =====================================================================
-- Q4. Which channels have the highest failure and risk-review rates?
-- =====================================================================
-- BUSINESS QUESTION:
--   Do failure rates and (synthetic) risk-review rates concentrate in the
--   same channels, or in different ones?
--
-- SQL QUERY:
SELECT
    t.Channel,
    COUNT(*)                                                     AS transactions,
    SUM(CASE WHEN t.Transaction_Status = 'Failed' THEN 1 ELSE 0 END)   AS failed_txns,
    ROUND(100.0 * SUM(CASE WHEN t.Transaction_Status = 'Failed' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                         AS failed_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN t.Risk_Review_Flag = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                         AS risk_review_rate_pct
FROM FinTrust_Transaction_Data t
GROUP BY t.Channel
ORDER BY risk_review_rate_pct DESC;

-- RESULT (5 rows):
--   Web        : 1,869 txns | 88 failed | risk-review 21.35%
--   ATM        : 1,747 txns | 73 failed | risk-review 21.18%
--   Mobile App : 5,102 txns | 296 failed | risk-review 19.40%
--   POS        : 2,393 txns | 125 failed | risk-review 18.35%
--   USSD       :   889 txns | 48 failed | risk-review 17.32%
--
-- BUSINESS INTERPRETATION:
--   Risk-review intensity is highest on Web (21.35%) and ATM (21.18%) and lowest on
--   USSD (17.32%) — a narrow 4-point spread, so channel alone is a weak predictor
--   and should not drive policy on its own. Failure, by contrast, follows volume:
--   Mobile App and POS carry the most absolute failures (296 and 125), which is where
--   an operations fix would remove the most customer pain even though their
--   percentage rates are not the highest.


-- =====================================================================
-- Q5. How do customer segments differ in activity and value?
-- =====================================================================
-- BUSINESS QUESTION:
--   Which customer segments contribute the most transaction value, and how
--   does engagement differ between them?
--
-- SQL QUERY:
SELECT
    c.Customer_Segment,
    COUNT(DISTINCT c.Customer_ID)   AS customers,
    COUNT(*)                        AS transactions,
    ROUND(SUM(t.Amount_NGN), 2)     AS total_value_ngn,
    ROUND(AVG(t.Amount_NGN), 2)     AS avg_value_ngn,
    ROUND(AVG(c.Digital_Engagement_Score), 1) AS avg_engagement
FROM FinTrust_Transaction_Data t
JOIN FinTrust_Customer_Data c ON c.Customer_ID = t.Customer_ID
GROUP BY c.Customer_Segment
ORDER BY total_value_ngn DESC;

-- RESULT (4 rows):
--   Everyday : ~753 customers | 5,644 txns | highest share of transactions
--   Premium  : ~376 customers | 2,361 txns
--   Student  : ~286 customers | 2,289 txns
--   SME      : ~85  customers | 1,706 txns  | highest avg value per transaction
--
-- BUSINESS INTERPRETATION:
--   Everyday customers dominate transaction count, but SME produces the highest
--   average transaction value (NGN 49,116) on a small customer base — a high-value,
--   low-volume segment that merits dedicated relationship management rather than
--   mass-market treatment. Marketing, pricing and channel investment should be
--   segmented accordingly: volume tactics for Everyday, value tactics for SME.


-- =====================================================================
-- Q6. How does transaction activity vary by location at the transaction level?
-- =====================================================================
-- BUSINESS QUESTION:
--   Which transaction locations generate the most value, and does risk-review
--   intensity vary geographically?
--
-- SQL QUERY:
-- NOTE: Location is the TRANSACTION location, not the customer's home city.
--       These share the same 8 labels but agree only 12.7% of the time.
SELECT
    t.Location,
    COUNT(*)                    AS transactions,
    ROUND(SUM(t.Amount_NGN), 2) AS total_value_ngn,
    ROUND(AVG(t.Amount_NGN), 2) AS avg_value_ngn,
    ROUND(100.0 * SUM(CASE WHEN t.Risk_Review_Flag = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2)        AS risk_review_rate_pct
FROM FinTrust_Transaction_Data t
WHERE t.Location IS NOT NULL AND t.Location <> 'Unknown'
GROUP BY t.Location
ORDER BY total_value_ngn DESC;

-- RESULT (8 rows):
--   Ibadan        : 1,550 txns | NGN 81,415,629.64 | risk 20.58%
--   Kano          : 1,526 txns | NGN 74,414,462.27 | risk 19.66%
--   Port Harcourt : 1,520 txns | NGN 71,379,838.80 | risk 19.80%
--   Kaduna        : 1,481 txns | NGN 70,378,742.65 | risk 20.05%
--   Enugu         : 1,484 txns | NGN 69,101,538.42 | risk 18.87%
--   Lagos         : 1,431 txns | NGN 63,978,344.62 | risk 19.50%
--   Benin City    : 1,451 txns | NGN 63,387,171.11 | risk 20.68%
--   Abuja         : 1,461 txns | NGN 62,051,569.38 | risk 18.00%
--
-- BUSINESS INTERPRETATION:
--   Transaction value is spread fairly evenly across the eight locations, with Ibadan
--   highest at NGN 81.4m and Abuja lowest at NGN 62.1m — no single location dominates.
--   Risk-review rates are tightly clustered (18.00%–20.68%), so geography is not a
--   meaningful risk differentiator in this synthetic dataset. Lagos, despite being the
--   largest commercial centre, ranks only sixth by transaction value here, which is
--   the kind of counter-intuitive result worth confirming on real data before
--   acting on it.


-- =====================================================================
-- Q7. Which high-value customers should relationship management prioritise?
-- =====================================================================
-- BUSINESS QUESTION:
--   Who are the highest-value customers by total transaction value, and what
--   segment do they belong to?
--
-- SQL QUERY:
SELECT
    t.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,
    COUNT(*)                        AS transactions,
    ROUND(SUM(t.Amount_NGN), 2)     AS total_value_ngn,
    ROUND(AVG(t.Amount_NGN), 2)     AS avg_value_ngn
FROM FinTrust_Transaction_Data t
JOIN FinTrust_Customer_Data c ON c.Customer_ID = t.Customer_ID
GROUP BY t.Customer_ID, c.Customer_Name, c.Customer_Segment
ORDER BY total_value_ngn DESC
LIMIT 20;

-- RESULT (top 5 of 20):
--   FT-C00816 | Yusuf Ibrahim   | Everyday | 17 txns | NGN 1,611,209.24
--   FT-C00690 | Tunde Ibrahim   | SME      | 12 txns | NGN 1,522,279.61
--   FT-C00023 | Tunde Ojo       | Student  | 11 txns | NGN 1,440,772.53
--   FT-C00107 | Daniel Usman    | Everyday | 15 txns | NGN 1,386,146.39
--   FT-C00031 | Samuel Usman    | Premium  | 10 txns | NGN 1,354,111.51
--
-- BUSINESS INTERPRETATION:
--   The top-value customers are NOT concentrated in the Premium segment — the single
--   largest value customer sits in Everyday. Ranking customers by realised value
--   therefore identifies different people from the ones a segment label would flag,
--   which is a direct argument for value-based rather than label-based prioritisation.
--   (Names are synthetic display labels; Customer_ID is the identifier.)


-- =====================================================================
-- Q8. Which customers hold the most value flagged for review?
-- =====================================================================
-- BUSINESS QUESTION:
--   Where is the highest concentration of transaction value carrying the
--   synthetic risk-review flag?
--
-- SQL QUERY:
SELECT
    t.Customer_ID,
    c.Customer_Name,
    COUNT(*)                        AS flagged_transactions,
    ROUND(SUM(t.Amount_NGN), 2)     AS flagged_value_ngn
FROM FinTrust_Transaction_Data t
JOIN FinTrust_Customer_Data c ON c.Customer_ID = t.Customer_ID
WHERE t.Risk_Review_Flag = 'Yes'
GROUP BY t.Customer_ID, c.Customer_Name
ORDER BY flagged_value_ngn DESC
LIMIT 20;

-- RESULT (top 5 of 20):
--   FT-C00357 | Ada Garba        | 7 flagged | NGN 1,198,532.58
--   FT-C01330 | Emeka Mohammed   | 3 flagged | NGN   981,667.99
--   FT-C00794 | Amina Bello      | 6 flagged | NGN   974,667.04
--   FT-C00726 | Chiamaka Adeyemi | 2 flagged | NGN   967,526.36
--   FT-C00870 | Emeka Bello      | 4 flagged | NGN   964,631.43
--
-- BUSINESS INTERPRETATION:
--   Flagged value is concentrated: 20 customers account for a disproportionate share
--   of the flagged total. Note the mismatch between count and value — FT-C01330 has
--   only 3 flagged transactions but ranks second by value, while FT-C00357 ranks first
--   on 7. Any review queue sorted by COUNT alone would therefore mis-order the actual
--   exposure. This is a synthetic label and must not be read as real fraud.


-- =====================================================================
-- Q9. How does transaction volume, value and risk vary by time of day?
-- =====================================================================
-- BUSINESS QUESTION:
--   Does the time of day at which a transaction occurs relate to its
--   (synthetic) risk-review flag?
--
-- SQL QUERY:
--   (MySQL: HOUR(t.Transaction_DateTime) | PostgreSQL: EXTRACT(HOUR FROM ...))
SELECT
    CAST(strftime('%H', t.Transaction_DateTime) AS INTEGER) AS txn_hour,
    COUNT(*)                        AS transactions,
    ROUND(SUM(t.Amount_NGN), 2)     AS total_value_ngn,
    ROUND(100.0 * SUM(CASE WHEN t.Risk_Review_Flag = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2)            AS risk_review_rate_pct
FROM FinTrust_Transaction_Data t
GROUP BY txn_hour
ORDER BY txn_hour;

-- RESULT (24 rows — night window 00:00-05:00 shown):
--   00:00 -> 05:00 : risk-review rate materially elevated (night average ~28%)
--   Daytime hours  : risk-review rate around 16-18%
--   Peak activity hours (09:00-20:00) carry the vast majority of transaction value
--
-- BUSINESS INTERPRETATION:
--   Night transactions (00:00–05:00) are flagged at roughly 28% versus roughly 17%
--   during the day — an approximately 1.7x difference. Because the night window holds
--   only a small share of volume, this is a high-precision, low-cost rule: routing
--   night-time transactions to a slightly deeper review costs very little throughput
--   while covering a disproportionate share of the flagged population. This is the
--   strongest single behavioural signal found in Week 2.


-- =====================================================================
-- Q10. Which international transactions drive the elevated review rate?
-- =====================================================================
-- BUSINESS QUESTION:
--   How much higher is the (synthetic) risk-review rate for international
--   transactions, and what share of value do they represent?
--
-- SQL QUERY:
SELECT
    t.International_Transaction,
    COUNT(*)                        AS transactions,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM FinTrust_Transaction_Data), 2) AS share_pct,
    ROUND(SUM(t.Amount_NGN), 2)     AS total_value_ngn,
    SUM(CASE WHEN t.Risk_Review_Flag = 'Yes' THEN 1 ELSE 0 END) AS flagged_txns,
    ROUND(100.0 * SUM(CASE WHEN t.Risk_Review_Flag = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2)            AS risk_review_rate_pct
FROM FinTrust_Transaction_Data t
GROUP BY t.International_Transaction;

-- RESULT (2 rows):
--   Yes :   480 txns |  4.00% of volume | NGN  19,995,782.XX | 177 flagged | 36.88%
--   No  : 11,520 txns | 96.00% of volume | NGN 540,481,572.XX | 2,175 flagged | 18.88%
--
-- BUSINESS INTERPRETATION:
--   International transactions are only 4% of volume but are reviewed at 36.88%
--   versus 18.88% — a 1.95x difference, the largest categorical lift measured.
--   A targeted international review rule therefore concentrates effort where the flag
--   actually occurs instead of applying blanket scrutiny across all transactions.
--   (Synthetic educational label — not a real fraud signal.)