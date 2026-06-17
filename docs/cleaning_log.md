# Cleaning Log

**UrbanShift Couriers — Data & Analytics Capstone**
**Group Manchester | Owner: Data Engineer (Uwais)**

This log documents every data quality issue found during DataBrew profiling and cross-dataset validation, the decision taken, and the rationale. Issues are grouped by file. Row counts reflect the raw data as received (deliveries.csv: 100,110 rows; incidents.csv: 22,390; customers.csv: 120; couriers.csv: 65).

---

## deliveries.csv

| # | Issue | Rows affected | Decision | Rationale |
|---|---|---|---|---|
| D1 | **Exact duplicate rows** — fully identical records, attributed to a mobile app sync issue | 1,282 | Removed via Data Wrangler "Drop duplicates" (full-row match) | Exact duplicates carry no additional information and would inflate delivery counts and revenue totals. Removed first, before any other transform. |
| D2 | **Duplicate `delivery_id` with conflicting field values** — after exact-duplicate removal, 680 delivery IDs still appeared twice with differing `courier_id`/`city` | 1,360 rows (680 IDs) → 680 removed | Sorted by `delivery_id` and ran remove duplicates after the city reformat. | A single delivery_id must be unique for valid joins to incidents and for accurate counts. Where records conflicted, the more complete record was retained as the best available version. |
| D3 | **Inconsistent `city` values** — 24 string variants of the 6 real cities (mixed case + trailing whitespace, e.g. `London`, `london`, `LONDON`, `London `) | 24 variants → 6 canonical | Data Wrangler: strip whitespace, then convert to title case | Unstandardised city values would fragment any city-level aggregation (operational risk by city), silently splitting one city across multiple groups and understating per-city totals. |
| D4 | **Missing `courier_id`** — deliveries handled by third-party subcontractors whose IDs were not captured | 4,004 (4.00%) | Filled with placeholder `"SUBCONTRACTOR"`; rows retained | These rows carry valid revenue and status data needed for profitability and city analysis, so were not dropped. The placeholder allows subcontractor deliveries to be analysed as their own category in courier-level aggregations rather than silently excluded. |
| D5 | **`time_taken_minutes` outliers** — 1,429 values with z-score > 3 (range 248–451 min vs. mean 69.5, median 61) | 1,429 flagged | Flagged via a boolean column, not removed | These may be legitimate long-distance/rural deliveries rather than errors. Flagging preserves them for the Data Scientist to assess during EDA, keeping the decision open rather than baking a deletion into the pipeline. |
| D6 | **Revenue recorded on Failed and Returned deliveries** — 5,016 Failed and 2,978 Returned deliveries carry positive revenue (£3.23–£7.50) | 7,994 | Added a boolean flag (`revenue_on_failed_flag`) marking non-completed deliveries carrying revenue; original `revenue_gbp` left intact | Treating these naively would overstate realised revenue and distort any profitability/cost-to-serve analysis. Flagging (rather than overwriting) preserves the raw billed figure while letting analysts exclude or separately treat unrealised revenue downstream. **Business assumption:** failed/returned deliveries are treated as not realising revenue for profitability purposes — to be confirmed with stakeholders. |
| D7 | **`delivery_status` flagged as statistical outlier in DataBrew** (z-score −4.21 on the `Failed` category, 5,016 rows) | 0 (no action) | No action — investigated and dismissed | Profiling artifact: DataBrew computed numeric z-scores on a categorical column, treating the three status values as ordinal codes. Not a genuine data quality issue. Logged to record that it was investigated, not overlooked. |
| D8 | **Realised revenue treatment** (follow-on from D6) — `revenue_gbp` does not distinguish billed revenue from revenue actually realised on completed deliveries | 7,994 affected (Failed + Returned) | Added a derived `realised_revenue_gbp` column: equal to `revenue_gbp` where `delivery_status = 'Delivered'`, else `0.0`. Original `revenue_gbp` retained unchanged | Gives analysts both figures — billed (`revenue_gbp`) and realised (`realised_revenue_gbp`) — without destroying source data. "Billed vs realised" is a distinction a finance/audit audience understands, and using realised revenue for profitability prevents the ~£X overstatement that summing raw revenue across all statuses would cause. **Business assumption:** failed/returned deliveries realise £0 — to be confirmed with stakeholders. |

**Checks performed, no issues found (deliveries.csv):**
- `customer_id` referential integrity vs. customers.csv — all valid (0 unmatched)
- `courier_id` referential integrity vs. couriers.csv (non-null) — all valid (0 unmatched)
- `delivery_date` — all values parse as valid dates, range 2024-10-01 to 2025-06-30
- `revenue_gbp` — no negative or zero values

---

## incidents.csv

| # | Issue | Rows affected | Decision | Rationale |
|---|---|---|---|---|
| I1 | **Mixed `incident_date` formats** — column typed as string because both `YYYY-MM-DD` (18,986 rows) and `DD/MM/YYYY` (3,404 rows) appear, both 10 characters, preventing auto-type inference | 3,404 (the non-ISO rows) | Custom transform parsing both formats (ISO first, then `DD/MM/YYYY` fallback), recasting the column to a proper date type | A consistent date type is required for any time-based analysis (e.g. monthly incident trends) and for date-range joins. Mixed formats left as strings would break sorting and date arithmetic. |
| I2 | **Orphaned `delivery_id` references** — incident records referencing delivery IDs that do not exist in deliveries.csv (`D9000000`–`D9000004`), believed to be data entry errors | 5 | Identified via left join to deliveries; rows excluded from analysis | At 0.02% of incidents and with no matching delivery to attribute them to, these cannot contribute to any delivery-linked analysis. Documented and excluded rather than left to silently drop out of inner joins. |

**Checks performed, no issues found (incidents.csv):**
- Exact duplicate rows — none (0)
- Missing values across all columns — none (0)
- `incident_id` / `delivery_id` uniqueness — both fully unique (22,390 distinct), max 1 incident per delivery
- `incident_type` and `resolution_status` — no case/whitespace variants (6 and 3 clean categories respectively)

---

## customers.csv

| # | Issue | Rows affected | Decision | Rationale |
|---|---|---|---|---|
| C1 | **Non-unique `customer_name`** — 60 of 120 customers share a name with exactly one other account (different `customer_id`, city, industry, account manager) | 120 (informational) | No correction to source data; added an optional disambiguated display name (`customer_name + city`). All joins keyed on `customer_id` | Not a data defect — `customer_id` is unique and is used for all joins. Flagged because any downstream report keyed on `customer_name` instead of `customer_id` would silently merge two distinct accounts, corrupting per-customer figures. Preventative, not corrective. |

**Checks performed, no issues found (customers.csv):**
- Exact duplicate rows — none (0)
- Missing values across all columns — none (0)
- `customer_id` uniqueness — fully unique (120 distinct)
- `city`, `customer_size`, `industry`, `account_manager`, `payment_terms_days` — all clean, no case/whitespace variants
- `signup_date` — all parse as valid dates, range 2022-04-28 to 2024-08-23

---

## couriers.csv

No data quality issues found. File is clean.

**Checks performed, no issues found (couriers.csv):**
- Exact duplicate rows — none (0)
- Missing values across all columns — none (0)
- `courier_id` uniqueness — fully unique (65 distinct)
- `employment_type`, `city`, `shift_pattern` — all clean, no case/whitespace variants
- `hire_date` — all parse as valid dates, range 2022-07-10 to 2025-04-14
- All couriers in the roster appear in deliveries; all couriers referenced in deliveries exist in the roster

---

## Summary

| File | Issues found | Rows removed | Rows flagged/derived | Final row count |
|---|---|---|---|---|
| deliveries.csv | 7 (+1 dismissed artifact) | 1,962 (1,282 exact + 680 conflicting) | 9,423 flagged (1,429 time + 7,994 revenue) + `realised_revenue_gbp` derived | 98,148 |
| incidents.csv | 2 | 5 (orphaned refs) | — | 22,385 |
| customers.csv | 1 (informational) | 0 | 120 (display name) | 120 |
| couriers.csv | 0 | 0 | — | 65 |

**Cleaning order (deliveries):** drop exact duplicates → standardise city → resolve conflicting duplicate IDs → fill missing courier_id → flag time outliers → flag revenue-on-failed → derive realised revenue. City standardisation was deliberately placed before conflicting-ID resolution, as some apparent conflicts differed only by city capitalisation.

*All transforms built in SageMaker Data Wrangler and exported to S3 `curated/`. The Data Wrangler session was closed after export to avoid unnecessary `ml.m5.4xlarge` instance cost.*
