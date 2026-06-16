# Architecture Document

**UrbanShift Couriers — Data & Analytics Capstone**
**Group Manchester | Owner: Cloud & Operations Lead (Jameel)**

---

## 1. Overview

This document explains the AWS architecture used to clean, store, model, and analyse nine months of UrbanShift Couriers operational data (~98,000 delivery records, ~22,000 incident records, 120 customer accounts, 65 couriers — approximately 7MB raw). It covers the six services in scope, why each was chosen, how access is controlled via IAM, and how the design would change at 10x data volume.

The guiding principle throughout: **right-sized for an intermittent, small-data workload this week, with a clear and honest path to scale** — not over-engineered for a dataset this size, but not naive about what changes if UrbanShift's data volume grows.

---

## 2. Data Flow

```
Raw CSVs (customers, couriers, deliveries, incidents)
        │
        ▼
   S3 — raw/ prefix
        │
        ▼
AWS Glue DataBrew  ──► automated profiling, surfaces data quality issues
        │
        ▼
SageMaker Data Wrangler ──► visual cleaning flow (dedup, city standardisation,
        │                    date parsing, missing-value handling)
        ▼
   S3 — curated/ prefix
        │
        ▼
Redshift Serverless ──► schema (dim_customers, dim_couriers, fact_deliveries,
        │               fact_incidents) + curated analytical view
        │
        ├──► SQL queries (analytical_queries.sql) → business question answers
        │
        └──► SageMaker Canvas ──► churn prediction model → churn_watchlist.csv
                                    (exported to S3 — exports/ prefix)
```

All access to this pipeline is governed by two IAM roles, described in Section 4.

---

## 3. Service Choices and Justification

### Amazon S3
Acts as the data lake backbone, organised into three prefixes within a single bucket (`urbanshift-group-manchester`):

- `raw/` — original CSV extracts, untouched
- `curated/` — cleaned outputs from the Data Wrangler flow, loaded into Redshift
- `exports/` — model outputs (e.g. `churn_watchlist.csv`)

S3 was the obvious choice for raw and intermediate storage: it's the standard integration point for both DataBrew and Data Wrangler, costs are negligible at this data volume, and prefix-based organisation gives a clean separation of concerns that maps directly onto the two IAM roles (Section 4).

### AWS Glue DataBrew
Used on Day 1 to run automated data quality profiles against all four raw files. This gave the team a fast, visual way to confirm the data quality issues flagged in the brief (duplicate delivery records, inconsistent city names, mixed incident date formats, missing courier IDs, unmatched incident references) before committing to a cleaning approach — avoiding the trap of designing the schema around assumptions rather than evidence.

### SageMaker Data Wrangler
Chosen for the actual cleaning pipeline because it produces a reusable, visual transform flow rather than a one-off script — useful both for documentation (the cleaning log references specific Wrangler steps) and for reproducibility if UrbanShift provides a fresh data extract in future. Sessions run on an `ml.m5.4xlarge` instance, which is notably more expensive per hour than a standard notebook; sessions are closed immediately after the cleaning flow is exported to keep costs negligible for a project of this size.

### Redshift Serverless
Chosen over a provisioned Redshift cluster because the workload is **intermittent** — heavy use during Tuesday's load and Wednesday's analysis, near-zero use outside those windows. Serverless billing (per RPU-second) avoids paying for an always-on cluster that would sit idle most of the week. At ~7MB of raw data, even the smallest provisioned cluster would be significant over-provisioning.

Redshift hosts the relational schema (`dim_customers`, `dim_couriers`, `fact_deliveries`, `fact_incidents`) and the curated analytical view that joins all four — this view is the single source for both the SQL business-question queries and the SageMaker Canvas churn model, ensuring consistency between the two.

### SageMaker Canvas
Chosen specifically because it's no-code — per the brief's "one model, well defended" principle, the priority was an interpretable model the team could explain in business language, not the most sophisticated model achievable. Canvas trains directly against the curated Redshift view, keeping the feature set consistent with the SQL analysis.

### AWS IAM
Two roles (`urbanshift-analytics-role`, `urbanshift-dataeng-role`) plus a tutor-provided permissions boundary applied to both. Full detail in Section 4.

---

## 4. Cost Considerations

At this data volume (~7MB across four files, ~98K + ~22K rows), the architecture is essentially cost-negligible for the project week:

- **S3**: storage cost for a few MB is fractions of a penny
- **Redshift Serverless**: billed per RPU-second of active query time — appropriate given usage is concentrated in short bursts (Tuesday load, Wednesday analysis) rather than continuous
- **SageMaker Data Wrangler**: the one component with a meaningful hourly cost (`ml.m5.4xlarge`) — managed by closing sessions promptly after the cleaning flow is exported
- **SageMaker Canvas**: billed for build/training time on Day 3 only

---

## 5. What Changes at 10x Scale

At ~1GB of deliveries (~1,000,000 rows) and ~220,000 incidents:

- **S3**: still trivial in storage terms, but raw uploads would move from single flat CSVs to **monthly partitions** (e.g. `raw/deliveries/year=2025/month=06/`), making both DataBrew profiling and Data Wrangler processing more manageable, and enabling Redshift `COPY` to load incrementally rather than re-processing the full history each time
- **Redshift Serverless**: still appropriate — 1GB is well within Serverless's comfortable range, and the intermittent-usage cost model remains the right fit. A provisioned cluster would only become worth considering if query concurrency or always-on dashboards became a requirement
- **Loading strategy**: the current full-reload approach (re-load the entire curated dataset each time) would be replaced with **incremental loads** — only new/changed records since the last load, identified via the delivery date or a watermark column, reducing both load time and Redshift compute cost
- **Data Wrangler**: the cleaning flow itself wouldn't need to change logically, but would need to run against partitioned input rather than a single file, and sampling (rather than full-dataset preview) would become more important during flow development
- **IAM**: the role split and boundary design would remain unchanged — access control patterns don't need to scale with data volume, which is one of the benefits of getting this design right early regardless of current data size

---

## 6. Known Limitations and Lessons

- The custom-scoped IAM policies drafted for both roles were, in practice, supplemented with broader AWS-managed policies (`AmazonS3FullAccess`, `AmazonSageMakerFullAccess`, etc.) during setup, due to time constraints and an initial permissions blocker on the lab account (`iam:CreateRole` not granted to the student user by default, resolved via tutor). At production scale, these would be tightened to the prefix- and resource-scoped custom policies originally drafted — this is flagged here rather than left undocumented, in line with the brief's emphasis on honest caveats.
- `iam:PassRole` (required for SageMaker to assume an execution role on the user's behalf) was a non-obvious dependency not captured in the original access design — discovered during testing rather than planning. Worth noting as an example of why the testing step matters, not just policy creation.

---

*Schema diagram: see `schema_diagram.png`. Cleaning decisions: see `cleaning_log.md`. SQL: see `analytical_queries.sql` and `ddl.sql`.*
