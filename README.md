do "scripts/analysis.do"# Trade and Development Analysis Project

This project examines the relationship between trade openness and economic growth in Turkey using panel data analysis and dynamic panel techniques.

## Project Structure

- `data/`: Directory for storing raw and processed data files
- `scripts/`: Stata do-files for analysis
- `output/`: Directory for storing results, tables, and figures
- `docs/`: Documentation and notes

## Analysis Components

1. Data preparation and cleaning
2. Descriptive statistics
3. Panel data analysis
4. Dynamic panel estimation (System GMM)
5. Robustness checks

## Variables of Interest

- GDP growth rate
- Trade openness (Exports + Imports / GDP)
- Control variables:
  - Investment
  - Human capital
  - Inflation
  - Government expenditure
  - Institutional quality indicators

## Requirements

- Stata 14 or higher
- Required Stata packages:
  - xtabond2 (for System GMM)
  - outreg2 (for output tables)
  - estout (for exporting results)
