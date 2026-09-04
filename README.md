# 📈 Multi-Channel Marketing Analytics: Campaign Performance & Efficiency Dashboard

[![Tableau Public](https://img.shields.io/badge/Tableau_Public-Interactive_Dashboard-E97627?style=flat&logo=tableau&logoColor=white)](https://public.tableau.com/views/MarketingPerformanceOverview_17883666080780/MarketingPerformanceOverview?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
[![SQL ETL](https://img.shields.io/badge/SQL-PostgreSQL_ETL-336791?style=flat&logo=postgresql&logoColor=white)](sql/marketing_ads_data.sql)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 📌 Executive Summary
This project delivers an end-to-end **Multi-Channel Marketing Performance & Efficiency System** in **Tableau Public**, powered by custom **SQL ETL data preparation** in PostgreSQL (DBeaver). 

The platform consolidates advertising spend, engagement, and conversion metrics across fragmented sources (**Facebook Ads** and **Google Ads**), joining relational fact tables with dimension lookups, decoding UTM campaign tracking parameters, and normalizing core marketing KPIs. The resulting interactive dashboard evaluates overall ROI ($28.62\text{M}$ total spend generating $12.26\text{K}$ leads at $1.22$ ROMI), budget-to-lead correlation ($77.76\%$), and cross-channel campaign efficiency.

---

## 🎯 Business Problem
* **Data Fragmentation**: Marketing performance data was split across siloed Facebook and Google Ads tables with encrypted IDs, missing dimension attributes, and encoded UTM query parameters.
* **Budget Scalability (Spend vs. Leads)**: Does increasing multi-channel ad spend yield proportional lead volume, or are specific channels hitting diminishing marginal returns?
* **Cost Efficiency & Unit Economics**: Which campaigns and ad sets yield optimal Cost Per Lead (CPL) and Return on Marketing Investment (ROMI), and how do cost metrics diverge between Google and Facebook over time?
* **Interactive Stakeholder Granularity**: How can marketing leads fluidly pivot between core funnel indicators (CTR, CPC, CPL, CPM, ROMI, Conversion Rates) without maintaining disconnected reports?

---

## 🛠 Tech Stack & Analytical Pipeline
* **Relational Database & SQL (PostgreSQL / DBeaver)**:
  * Fact-Dimension modeling: Joined Facebook ad facts with campaign and adset lookup dictionaries.
  * Cross-channel unification via `UNION ALL` across Google and Facebook records.
  * Extracted and sanitized `utm_campaign` values via custom URL decoding logic.
  * Handled NULLs and zeroes using `COALESCE` to maintain accurate aggregate math.
* **Tableau Public & Data Architecture**:
  * **Dynamic Parameter Switching**: Engineered `Select Metric` parameter controlling dynamic measures (CPL, CTR, CPC, CPM, ROMI, Clicks-to-Leads %, Reach-to-Leads %).
  * **Level of Detail (LOD) Calculations**: Built `FIXED` LOD expressions for monthly baseline spend and leads aggregation.
  * **Statistical Correlation**: Implemented floating correlation analysis ($r = 77.76\%$) between monthly ad investments and lead acquisition.
  * **Dashboard Actions**: Configured dynamic Scatter Plot Filter Actions targeting the Metric Trend and Dual-Axis charts by `campaign_name`.

---

## 🔍 Key Findings & Analytical Insights

| Analytical Dimension | High-Performance Benchmark | Critical Risk / Inefficiency Area | Strategic Takeaway |
| :--- | :---: | :---: | :--- |
| **Channel Correlation** | **Lead Correlation ($77.76\%$)** | **Late 2022 Cost Spikes** | Spend heavily drives lead volume, but late-stage CPL escalations indicate audience saturation. |
| **Top Campaigns (Volume)** | **Brand ($26\text{K}$+ Leads)** | **Discounts / Crazy Discounts** | Brand search dominates total volume; promo-driven sets exhibit low volume and high volatility. |
| **Platform Dynamic** | **Facebook (Stable Baseline)** | **Google (Late 2022 Lead Surge)** | Google exhibited rapid lead expansion in late 2022 alongside increased CPL volatility. |
| **Aggregate Unit Economics** | **Overall ROMI ($1.22$)** | **Average CPL ($\$2,335.35$)** | Positive return on investment, but top-of-funnel conversion requires granular retargeting optimization. |

* **Strong Budget Correlation ($77.76\%$)**: Dual-axis monthly tracking confirms a tight relationship between ad capital deployed and lead volume, validating budget scalability.
* **Volume Concentration**: The `Brand` and `Expansion` campaigns account for the vast majority of all acquired leads ($26.9\text{k}$ and $19.1\text{k}$ combined across channels), while peripheral discount campaigns show marginal returns.
* **Channel Parity & CPL Trajectory**: While Facebook maintained a stable expenditure baseline, Google Ads experienced a sharp volume surge in Q3–Q4 2022, accompanied by higher per-lead acquisition costs.

---

## 💡 Strategic Recommendations
1. **Capital Allocation to Core Drivers**: Reallocate underperforming ad budget from low-yield campaigns (`Discounts`, `Crazy discounts`) into high-efficiency drivers (`Brand` and `Expansion`) to maximize lead generation efficiency.
2. **Cap Escalating CPL on Google Ads**: Investigate late-2022 CPL escalation on Google channels; apply negative keyword lists and tighter bidding caps to restore efficiency.
3. **Multi-Touch Retargeting Loops**: Improve the 0.90% CTR and Clicks-to-Leads funnel conversion by implementing dedicated landing pages tailored to specific UTM campaign tags.

---

## ⚙️ Core Technical Implementation

### SQL Unified Dataset Pipeline
```sql
WITH fb_cleaned AS (
    SELECT 
        f.ad_date,
        'Facebook' AS source,
        c.campaign_name,
        a.adset_name,
        COALESCE(f.spend, 0) AS spend,
        COALESCE(f.impressions, 0) AS impressions,
        COALESCE(f.reach, 0) AS reach,
        COALESCE(f.clicks, 0) AS clicks,
        COALESCE(f.leads, 0) AS leads,
        COALESCE(f.value, 0) AS value,
        f.url_parameters
    FROM public.facebook_ads_basic_daily f
    LEFT JOIN public.facebook_campaign c ON f.campaign_id = c.campaign_id
    LEFT JOIN public.facebook_adset a ON f.adset_id = a.adset_id
),
google_cleaned AS (
    SELECT 
        g.ad_date,
        'Google' AS source,
        g.campaign_name,
        g.adset_name,
        COALESCE(g.spend, 0) AS spend,
        COALESCE(g.impressions, 0) AS impressions,
        COALESCE(g.reach, 0) AS reach,
        COALESCE(g.clicks, 0) AS clicks,
        COALESCE(g.leads, 0) AS leads,
        COALESCE(g.value, 0) AS value,
        g.url_parameters
    FROM public.google_ads_basic_daily g
)
SELECT * FROM fb_cleaned
UNION ALL
SELECT * FROM google_cleaned;

```
---
Tableau Calculated Fields & LOD Formulas

- Monthly Leads (LOD):
{ FIXED DATETRUNC('month', [Ad Date]) : SUM([Leads]) }

- Monthly Spend (LOD):
{ FIXED DATETRUNC('month', [Ad Date]) : SUM([Spend]) }

- Dynamic Metric Selector:
CASE [Select Metric]
    WHEN 'CPL' THEN [Spend] / NULLIF([Leads], 0)
    WHEN 'CTR' THEN ([Clicks] / NULLIF([Impressions], 0)) * 100
    WHEN 'CPC' THEN [Spend] / NULLIF([Clicks], 0)
    WHEN 'CPM' THEN ([Spend] / NULLIF([Impressions], 0)) * 1000
    WHEN 'ROMI' THEN [Value] / NULLIF([Spend], 0)
END

📊 Project Structure & Deliverables

marketing-performance-analytics-tableau/
├── LICENSE
├── README.md
├── sql/
│   └── marketing_ads_data.sql
├── dashboards/
│   └── Marketing_Performance_Overview.twbx
├── data/
│   └── marketing_ads_data.csv
└── images/
    └── Marketing_Performance_Overview.png

🔗 Interactive Tableau Public Dashboard: Live Dashboard Link

📄 SQL Pipeline Source: sql/marketing_ads_data.sql

📈 Dashboard Preview

- Top KPI Scorecards: Macro tracking of Spend, Impressions, Clicks, Leads, CTR, CPC, CPL, CPM, and ROMI.
- Spend vs. Leads Dual-Axis Analysis: Monthly expenditure vs. lead volume with floating correlation tracking ($77.76\%$).
- Dynamic Metric Trend: Longitudinal performance broken down by advertising source (Facebook vs. Google).
- Campaign Ranking: Horizontal performance hierarchy sorted by the active selected metric.
- Campaign Efficiency Scatter Plot: Interactive multi-attribute correlation matrix (Spend vs. Efficiency by Lead Volume).

## ✉️ Contact

**Author:** Oleksandr Hordashevskyi

- LinkedIn: [Oleksandr Hordashevskyi](https://www.linkedin.com/in/oleksandr-hordashevskyi)
- Email: [o.hordashevskyi@gmail.com](mailto:o.hordashevskyi@gmail.com)
