![Kings Peak](Docs/Kings.Peak.jpg)
*A photo I took of King's Peak wayyyy in the center background. This is Utah's tallest mountain standing at an elevation of 4125m (13,528ft)!*


## Welcome!
This project demonstrates an end-to-end data engineering pipeline that tracks weather conditions across Utah's 50 highest mountain peaks. By pulling real-time forecasts from multiple APIs and transforming them into analytics-ready datasets, my project showcases skills in ETL development, database design, workflow orchestration, and data visualization. 

Besides being able to explore more of my love for the mountains, I also designed this portfolio project to increase my skills and develop best practices in data engineering and analytics. Explore and enjoy! 


## How It Works?

### Data Flow
![Data Flow]()

**Data Sources:**
- Wikipedia: Top 50 Highest Summits/Mountains in Utah
- Weather Codes: https://gist.github.com/stellasphere/9490c195ed2b53c707087c8c2db4ec0c
- OpenMeteo API: Daily (7-day forecast), hourly (24-hour forecast), and 15-minute lightning potential data
- OpenWeather API: Live weather alerts


### Incremental Logic
All bronze-to-silver transformations use incremental processing to efficiently handle new data while preventing duplicates. The pipeline compares the `pulled_at` timestamp from bronze against the maximum `pulled_at` in silver using a `>=` filter, ensuring no records are missed when multiple pulls share the same timestamp.

**Upsert behavior:**
- **Daily data**: Stores 7-day forecast history with `(mtn_id, dly_time, pulled_at)` primary key to track how predictions evolve over time
- **Hourly/Lightning data**: Updates in place with `(mtn_id, time)` primary key for current conditions
- **Alerts**: Maintains only active alerts (no historical tracking)

This approach allows the pipeline to safely rerun without creating duplicates while preserving forecast trends.


**Data Retention:**
A 6-month rolling window balances historical analyses with storage efficiency for my local computer. Automated cleanup runs daily via Airflow to maintain optimal database size.

### Apache Airflow Orchestration
*Describe my DAG structure, scheduling intervals, task dependencies, monitoring/alerting setup*

### Insights
*Describe some interesting insights from data analysis*


## Data Architecture
The database follows the **medallion architecture** (Bronze -> Silver -> Gold) style. Data is first stored raw, then transformed, and finally loaded into tables/views ready for analysis and visualizations.

![DWH Layers](Docs/DWH%20Layers.png)

**Bronze Layer (Raw)** 
- Stores data exactly as received from APIs
- JSON format preserved for full fidelity
- Serves as immutable source of truth
- Tables: `openmeteo_daily`, `openmeteo_hourly`, `openmeteo_lightning`, `openweather_alerts`, `wki_mtns`

**Silver Layer (Cleaned & Normalized)**
- Flattens nested JSON into relational tables
- Implements incremental upsert logic
- Handles deduplication and data quality checks
- Tables mirror bronze structure with typed columns

3. **Gold (Analytical Ready)**
- Views for specific use cases
- Aggregated metrics


## Tools & Technologies

**Python 3.14.0**: API extraction, data validation, error handling

**PostgreSQL 18**: Relational database with JSONB support for semi-structured data, incremental load patterns

**SQL**: Complex transformations including JSON parsing, array unnesting, window functions, upserts

**Apache Airflow**: Workflow orchestration, scheduling, dependency management, monitoring

**Power BI**: Interactive dashboards for tracking trends, hiking conditions, and more

**R/ggplot2**: Statistical analysis and visualizations

**Git/GitHub**: Version control and project documentation


## Repository Structure

```py
Utah-Mountain-Conditions-DE/
│
├── Wiki Data/                          # Saved CSVs of the top 50 tallest utah mountains table extract from wikipedia 
│
├── Docs/                               # Project documentation and architecture details
│   ├── Kings.Peak.jpg                  # Project photo
│   ├── DWH Layers.png                  # Diagram showing the medallion architecture used for this project
│   ├── Data Flow.png                   # Diagram showing the flow of data
│   ├── Data Sources.doc                # Doc listing the data sources used with URLs 
│   ├── Project Goals.doc               # Personal learning goals for this project
│
├── Scripts/                            # Scripts for ETL/ELT processes and analyses
│   ├── Python                          # Python scripts
│   ├── SQL                             # SQL scripts
│   ├── R                               # R scripts
|
├── README.md                           # Project overview and details
├── .gitignore                          # Private info to be ignored by git
└── requirements.txt                    # Dependencies and requirements used for the project
```

## Author

**Tavish King**

Data Analyst/Jr. Data Engineer

Feel free to connect on [LinkedIn](https://www.linkedin.com/in/tavish-king/) or check out more of my work!


