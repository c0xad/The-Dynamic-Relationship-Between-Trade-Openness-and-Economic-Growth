/*******************************************************************************
* Analysis of Trade Openness and Economic Growth in Turkey
*******************************************************************************/

clear all
set more off
capture log close

* Set working directory
cd "c:/Users/eren/Desktop/fundshedge"

* Start log file
log using "output/analysis_log.txt", replace

* Load the prepared dataset
use "data/turkey_macro_data.dta", clear

* Basic descriptive statistics
estpost summarize gdp_growth trade_gdp investment inflation govt_exp tertiary_educ
esttab using "output/summary_statistics.csv", cells("count mean sd min max") replace

* Correlation analysis
estpost correlate gdp_growth trade_gdp investment inflation govt_exp tertiary_educ, matrix
esttab using "output/correlation_matrix.csv", replace

* Time series plots
foreach var in gdp_growth trade_gdp investment inflation govt_exp tertiary_educ {
    twoway (line `var' year), title("`var' over time") ///
    ytitle("`var'") xtitle("Year") ///
    saving("output/`var'_trend.gph", replace)
}

* Basic regression analysis
* Model 1: Basic relationship
reg gdp_growth trade_gdp investment inflation govt_exp tertiary_educ

* Model 2: With interaction terms
reg gdp_growth trade_gdp investment inflation govt_exp tertiary_educ ///
    trade_inv_int trade_educ_int

* Model 3: With squared term for potential non-linear relationship
reg gdp_growth trade_gdp trade_gdp_sq investment inflation govt_exp tertiary_educ ///
    trade_inv_int trade_educ_int

* Export regression results
eststo clear
eststo: reg gdp_growth trade_gdp investment inflation govt_exp tertiary_educ
eststo: reg gdp_growth trade_gdp investment inflation govt_exp tertiary_educ ///
    trade_inv_int trade_educ_int
eststo: reg gdp_growth trade_gdp trade_gdp_sq investment inflation govt_exp tertiary_educ ///
    trade_inv_int trade_educ_int

esttab using "output/regression_results.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Regression Results") ///
    mtitles("Model 1" "Model 2" "Model 3") ///
    stats(N r2_a F p) ///
    note("* p<0.10, ** p<0.05, *** p<0.01")

* Close log file
log close
