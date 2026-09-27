# FinTrust Digital Bank - Week 2 Analytics (AnalystLab Africa)

Week 2 practical execution for the FinTrust Financial Intelligence & Digital Banking
Support Solution project. Track: Data Analytics.

## Project overview
FinTrust Digital Bank wants to understand its transaction behaviour and risk-review
patterns. This repository contains the Week 2 data preparation, SQL analysis, Python
exploratory analysis, management dashboard and business findings.

## Dataset
Synthetic, educational data supplied for the assignment.
- 1,500 customers (12 fields)
- 12,000 transactions, Jan-Mar 2026 (11 fields)
- Join key: Customer_ID (0 orphans, 100% match)

## Repository structure
```
data/       cleaned datasets used for analysis
notebooks/  Python EDA notebook and model-development notebook
sql/        business-question SQL analysis (10 questions)
outputs/    dashboard, data-quality workbook, SQL results, metrics
docs/       business findings, project documentation, summaries
charts/     exported chart images
```

## Key metrics
| Metric | Value |
|---|---|
| Total customers | 1,500 |
| Total transactions | 12,000 |
| Total transaction value | NGN 560,477,355 |
| Average transaction value | NGN 46,706 |
| Transaction success rate | 90.47% |
| Risk review rate | 19.60% |
| Value under risk review | NGN 161.8M |

## How to run
```
pip install -r requirements.txt
# open notebooks/FinTrust_Week2_Data_Analysis.ipynb in Jupyter or Colab
# run sql/FinTrust_Week2_SQL_Analysis.sql in SQLite or DuckDB
```

## Data disclaimer
All FinTrust data is synthetic and created for educational purposes only. The
Risk_Review_Flag is a synthetic educational label and is not a real fraud
determination or real banking risk decision.
