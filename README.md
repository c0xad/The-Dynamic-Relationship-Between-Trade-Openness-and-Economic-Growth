# The Dynamic Relationship Between Trade Openness and Economic Growth

This repository contains research analyzing the dynamic relationship between trade openness and economic growth, with a particular focus on developing economies and panel data analysis.

## Project Overview

This research project investigates how trade openness affects economic growth through various channels, using advanced econometric techniques including panel data analysis and dynamic modeling. The study examines both direct effects and interaction effects with other economic variables.

## Repository Structure

```
fundshedge/
├── data/               # Raw and processed economic data files
├── docs/              # Documentation and methodology notes
├── output/            # Generated analysis outputs (tables, figures)
├── scripts/           # Stata analysis scripts
│   ├── analysis.do           # Main analysis script
│   ├── advanced_analysis.do  # Advanced econometric analyses
│   └── data_preparation.do   # Data cleaning and preparation
└── paper.tex          # Research paper manuscript
```

## Data Components

The analysis utilizes several datasets containing economic indicators:
- Trade openness metrics (exports + imports as % of GDP)
- GDP growth rates
- Investment data
- Human capital indicators
- Macroeconomic variables
- Institutional quality measures

## Analysis Components

1. **Data Preparation** (`data_preparation.do`)
   - Economic data cleaning and standardization
   - Variable construction and transformation
   - Panel data formatting
   - Treatment of missing values

2. **Main Analysis** (`analysis.do`)
   - Descriptive statistics of trade and growth patterns
   - Panel regression analysis
   - Fixed and random effects models
   - Causality testing
   - Generation of summary statistics and correlation matrices

3. **Advanced Analysis** (`advanced_analysis.do`)
   - Dynamic panel estimation (System GMM)
   - Interaction effects analysis
   - Threshold effects in trade-growth relationship
   - Robustness checks and sensitivity analyses

## Key Variables

### Dependent Variables
- GDP growth rate
- Per capita GDP growth

### Independent Variables
- Trade openness (Exports + Imports / GDP)
- Investment rates
- Human capital indicators
- Inflation rates
- Government expenditure
- Institutional quality measures
- Financial development indicators

## Output Files

The analysis generates various outputs in the `output/` directory:
- Summary statistics tables
- Correlation matrices
- Panel regression results
- Granger causality test results
- Time series plots
- Interactive effects visualizations

## Requirements

### Software
- Stata 14 or higher

### Required Stata Packages
- `xtabond2`: For dynamic panel estimation (System GMM)
- `estout`: For exporting estimation results
- `outreg2`: For creating publication-ready tables
- Additional packages as specified in the scripts

## Usage

1. Clone this repository
2. Set the working directory to the project root
3. Run the scripts in the following order:
   ```stata
   do "scripts/data_preparation.do"
   do "scripts/analysis.do"
   do "scripts/advanced_analysis.do"
   ```

## Documentation

Detailed documentation of the econometric methods, variable definitions, and theoretical framework can be found in the `docs/` directory.

## Paper

The research findings are documented in `paper.tex`, which contains the full manuscript with methodology, results, and discussion sections.

## Contact

For questions about the research or potential collaborations, please contact the repository maintainers.

## License

This project is licensed under appropriate academic research terms. Please cite this work if you use any part of this analysis in your research.
