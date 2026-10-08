# Retail Demand & Market Intelligence Analytics

**From transactions to the trading floor.** An end-to-end retail analytics project that takes roughly one million raw e-commerce transactions, turns them into a trustworthy dataset, and investigates whether seasonal demand in the transactions lines up with retail stock performance.

| | |
|---|---|
| **Dataset** | Online Retail II, UCI Machine Learning Repository |
| **Period** | December 2009 to December 2011 |
| **Scale** | 1,027,614 rows × 15 columns after cleaning |
| **Stack** | Python, pandas, SQL, Parquet, Git and GitHub |
| **Focus** | Data cleaning, SQL analysis, exploratory analysis, dashboarding |

<!-- Optional: add a dashboard screenshot here, e.g. ![Dashboard](dashboard/preview.png) -->
<!-- Optional: add a link to the published dashboard here. -->

---

## Why this project

Retail data looks simple until you try to trust it. Cancellations, internal stock adjustments, anonymous customers and pricing errors all sit in the same table as genuine sales. This project shows the full workflow a data analyst follows:

1. Understand the data and question its quality.
2. Clean it with every decision documented and justified.
3. Analyse it with SQL and Python.
4. Present the results as a business story.

It is designed to show both sides of analytics: rigorous SQL and market analysis, and clear business narrative and recommendations.

## Research question

> Do seasonal demand patterns in retail transactions correspond to patterns in retail-sector stock performance?

## Dataset

**Online Retail II** contains transactions from a UK-based online retailer between December 2009 and December 2011, with more than one million rows. Each row is one product line on an invoice, including quantity, unit price, invoice date, customer ID and country. The data also contains cancellations and non-product entries, which is what makes the cleaning phase important.

The project also brings in retail-sector stock market data (external) to compare against demand patterns.

## Approach

| Phase | Focus | Status |
|---|---|---|
| 1. Data understanding | Structure, nulls, duplicates, geography, cancellations, revenue construction | Complete |
| 2. Data cleaning | Nine documented, sequential cleaning steps | Complete |
| 3. Exploratory analysis | Monthly revenue trends, seasonality, product and country views | In progress |
| 4. Advanced analytics | Customer segmentation (RFM), demand forecasting, churn and CLV | Planned |
| 5. Market integration | Combine demand patterns with retail stock performance | Planned |
| 6. Dashboard | Interactive summary of the findings | See `dashboard/` |

## Data understanding highlights

- Missing Customer IDs make up about 22.7% of the data and are concentrated in the UK. They are **not randomly distributed**, so they cannot be dropped or imputed without distorting the analysis.
- Cancellations and internal stock adjustments are mixed in with genuine sales and need separate handling.
- A revenue column was constructed from quantity and unit price to support the later analysis.

## Data cleaning

Every step was reasoned and documented before any code was written. Cleaning was done one step at a time, in this order:

| # | Step | What was done |
|---|---|---|
| 1 | Type corrections | `InvoiceDate` converted to datetime; `Customer ID` converted to a nullable integer so missing IDs are preserved |
| 2 | Duplicates | About 34K exact duplicate rows removed |
| 3 | Non-product codes | 13 confirmed non-product StockCodes excluded (postage, bank charges, adjustments, test entries and similar) |
| 4 | Stock adjustments | About 5,929 internal stock adjustment rows (no Customer ID, zero price, not cancelled) flagged, and kept separate from 63 genuine promotional free-item rows |
| 5 | Cancellation matching | Cancellations paired with original purchases by Customer ID, StockCode, exact quantity and strict temporal order; matched 35.4% by row count and 87.2% by cancelled units |
| 6 | Anonymous rows | About 22.7% of rows with no Customer ID **retained** for revenue and product analysis, and filtered only for customer-level work (RFM, segmentation) |
| 7 | Descriptions | Product descriptions standardised by majority vote across genuine sales rows (`Description_clean`) |
| 8 | Price outliers | Prices flagged at 10× the StockCode median on genuine rows only, correcting 744 rows (`Price_clean`) |
| 9 | Final dataset | 1,027,614 rows × 15 columns, saved as Parquet (about 10 MB, committed) and CSV (about 154 MB, git-ignored) |

### Design principles

- **Reason before code.** Each step is documented with its rationale before it is implemented.
- **Retain, don't impute.** Anonymous rows are kept globally and filtered only where a question needs customer identity.
- **Distinguish look-alikes.** Internal stock adjustments and genuine promotional free items both have zero prices, so telling them apart takes multi-condition logic, not a simple filter.
- **Validate heuristics against the data.** Reviewing the output caught test StockCodes with numeric suffixes that a first heuristic missed, and a bug that applied the price-outlier flag to every row instead of genuine rows only (752 corrected rows instead of 744).

## Repository structure

```
.
├── data/            # raw, interim, processed and external data (Cookiecutter Data Science layout)
├── notebooks/       # numbered analysis notebooks, one set per phase
├── sql/             # SQL queries for the retail analysis
├── dashboard/       # dashboard files
├── requirements.txt # Python dependencies
├── LICENSE
└── README.md
```

## Getting started

```bash
# 1. Clone the repository
git clone https://github.com/MohanKumarN14/Retail-Demand-and-Market-Intelligence-Analytics.git
cd Retail-Demand-and-Market-Intelligence-Analytics

# 2. Create and activate a virtual environment
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS / Linux:
source .venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt
```

Then open the notebooks in VS Code or Jupyter and run them in numeric order.

The cleaned dataset is committed as Parquet, so you can start analysing without repeating the cleaning phase. The much larger CSV copy is git-ignored and can be regenerated by running the cleaning notebook.

<!-- If the raw Online Retail II file is not committed, add: "Download Online Retail II from the UCI Machine Learning Repository and place it in data/raw/ before running the notebooks." -->

## Tools

- **Python** and **pandas** for cleaning and analysis
- **SQL** for the retail analysis queries in `sql/`
- **Parquet** for efficient storage of the cleaned dataset
- **VS Code** with a virtual environment
- **Git and GitHub** for version control, with a Cookiecutter-style project layout

## Roadmap

<!-- Tick a box when the step is finished. -->

- [x] Phase 1: Data understanding
- [x] Phase 2: Data cleaning (nine documented steps)
- [ ] Phase 3: Exploratory analysis (monthly revenue and seasonality)
- [ ] Customer segmentation (RFM)
- [ ] Demand forecasting
- [ ] Churn and customer lifetime value modelling
- [ ] Stock market data integration and cross-analysis
- [ ] Final dashboard and written recommendations

## Author

**Mohan N**, B.E. Computer Science & Engineering student, aspiring Data Scientist.

[GitHub](https://github.com/MohanKumarN14) · [LinkedIn](https://www.linkedin.com/in/mohan-kumar-n14)

## License

See the [LICENSE](LICENSE) file for details.
