# SQL Data Pipeline Project

This project builds a complete data pipeline using Python, Faker, DuckDB, and SQL.  
It generates a synthetic e-commerce dataset (150k+ rows), loads it into DuckDB using an idempotent ETL script, and performs analysis with 50+ advanced SQL queries (joins, window functions, CTEs, subqueries).  
A Jupyter Notebook presents selected business insights.

---

## Project Structure

sql-pipeline-project/
├── scripts/              # Data generation + loading
│   ├── generate_data.py
│   └── load_to_duckdb.py
├── sql/queries.sql       # 50+ analytical queries
├── notebooks/analysis.ipynb
├── data/                 # Generated CSVs (ignored)
├── db/                   # DuckDB file (ignored)
├── requirements.txt
└── README.md

---

## Setup

### 1. Clone and enter project
git clone <your_repo_url>
cd sql-pipeline-project

### 2. Create virtual environment
# PowerShell
python -m venv venv
venv\Scripts\Activate

# Git Bash
python -m venv venv
source venv/Scripts/activate

### 3. Install dependencies
pip install -r requirements.txt

---

## Step 1 — Generate Synthetic Data
python scripts/generate_data.py  
Creates users, products, orders, order_items, payments in data/ (ignored in Git).

---

## Step 2 — Load Data into DuckDB
python scripts/load_to_duckdb.py  
Creates db/ecommerce.duckdb and loads all tables.  
Safe to rerun (idempotent).

---

## Step 3 — Run All SQL Queries

### Using DuckDB CLI:
duckdb db/ecommerce.duckdb
.read sql/queries.sql

### Or using Python:
import duckdb
con = duckdb.connect("db/ecommerce.duckdb")
con.execute(open("sql/queries.sql").read())

---

## Step 4 — Analysis Notebook
jupyter notebook  
Open notebooks/analysis.ipynb.  

Contains:
- Business questions  
- SQL queries  
- Query results  
- Insights  

---

## Notes
- data/ and db/ are excluded via .gitignore (as required).
- Pipeline is fully reproducible by running the four steps above.

---

## Summary
This project demonstrates realistic data engineering workflow:
data generation → schema creation → loading → advanced SQL analysis → reporting.
