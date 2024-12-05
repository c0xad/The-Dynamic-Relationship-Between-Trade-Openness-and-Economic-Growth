# Healthcare Economics Research Project

This repository contains the analysis of healthcare interventions effectiveness and cost-efficiency, focusing on antidiabetics, antihypertensives, and antiplatelet medications.

## Project Overview

This research project analyzes the efficacy, tolerability, and cost-effectiveness of various medical interventions across different therapeutic areas. The analysis includes both longitudinal and cross-sectional data analysis using Stata.

## Repository Structure

```
fundshedge/
├── data/               # Raw and processed data files
├── docs/              # Documentation and supplementary materials
├── output/            # Generated analysis outputs (figures, tables)
├── scripts/           # Stata analysis scripts
│   ├── analysis.do           # Main analysis script
│   ├── advanced_analysis.do  # Advanced statistical analyses
│   └── data_preparation.do   # Data cleaning and preparation
└── paper.tex          # Research paper manuscript
```

## Data Files

- `antidiabetics_efficacy_long.dta`: Longitudinal data on antidiabetic medication efficacy
- `antidiabetics_efficacy_wide.dta`: Wide-format data on antidiabetic medication efficacy
- `antidiabetics_tolerability.dta`: Tolerability data for antidiabetic medications
- `antidiabeticssucras.dta`: Specific analysis of SUCRA (Surface Under the Cumulative Ranking) for antidiabetics
- `antihypertensives.dta`: Data on antihypertensive medications
- `antiplatelet.dta`: Analysis data for antiplatelet interventions

## Analysis Components

1. **Data Preparation** (`data_preparation.do`)
   - Data cleaning and standardization
   - Variable construction and transformation
   - Dataset merging and formatting

2. **Main Analysis** (`analysis.do`)
   - Descriptive statistics
   - Time series analysis
   - Regression models with various specifications
   - Generation of summary statistics and correlation matrices

3. **Advanced Analysis** (`advanced_analysis.do`)
   - Complex statistical modeling
   - Interaction effects analysis
   - Robustness checks
   - Sensitivity analyses

## Key Variables

- Efficacy measures
- Tolerability indicators
- Cost metrics
- Treatment outcomes
- Patient characteristics
- Time-varying covariates

## Output Files

The analysis generates various outputs in the `output/` directory:
- Summary statistics
- Correlation matrices
- Regression results
- Time series plots
- Treatment effect visualizations

## Requirements

### Software
- Stata 14 or higher

### Required Stata Packages
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

Detailed documentation of the analysis methods and variable definitions can be found in the `docs/` directory.

## Paper

The research findings are documented in `paper.tex`, which contains the full manuscript with methodology, results, and discussion sections.

## Contact

For questions or collaborations, please contact the repository maintainers.

## License

This project is licensed under appropriate academic research terms. Please cite this work if you use any part of this analysis in your research.
