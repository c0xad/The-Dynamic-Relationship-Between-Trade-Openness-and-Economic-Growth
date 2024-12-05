/*******************************************************************************
* Advanced Analysis of Trade Openness and Economic Growth in Turkey
* Author: Eren
* Date: December 2024
*******************************************************************************/

clear all
set more off
capture log close

* Set working directory
cd "c:/Users/eren/Desktop/fundshedge"

* Start log file
log using "output/advanced_analysis_log.txt", replace

* Load the prepared dataset
use "data/turkey_macro_data.dta", clear

********************************************************************************
* 1. Enhanced Data Preparation
********************************************************************************
* Set time series
tsset year

* Generate period dummies for structural breaks
gen period1 = (year < 1980)        // Pre-liberalization
gen period2 = (year >= 1980 & year < 2001)  // Post-liberalization
gen period3 = (year >= 2001)       // Post-2001 crisis

* Label periods
label define periods 1 "Pre-liberalization" 2 "Post-liberalization" 3 "Post-2001"
label values period1 periods
label values period2 periods
label values period3 periods

* Generate 3-year moving averages for smoothed analysis
foreach var of varlist gdp_growth trade_gdp investment inflation govt_exp tertiary_educ {
    gen `var'_ma3 = (l1.`var' + `var' + f1.`var')/3
    label variable `var'_ma3 "3-year MA of `var'"
}

********************************************************************************
* 2. Descriptive Statistics
********************************************************************************
* Overall summary statistics
estpost summarize gdp_growth trade_gdp investment inflation govt_exp tertiary_educ, detail
esttab using "output/detailed_summary_stats.csv", ///
    cells("count mean sd min p25 p50 p75 max") ///
    label noobs replace

* Summary statistics by period
estpost tabstat gdp_growth trade_gdp investment inflation govt_exp tertiary_educ, ///
    by(period1) statistics(count mean sd min max) columns(statistics)
esttab using "output/summary_by_period.csv", ///
    cells("count mean(fmt(%9.2f)) sd(fmt(%9.2f)) min(fmt(%9.2f)) max(fmt(%9.2f))") ///
    noobs replace title("Summary Statistics by Period")

********************************************************************************
* 3. Enhanced Visualization
********************************************************************************
* Set graph style
set scheme s2color
graph set window fontface "Arial"

* Time series plots with trends and events
foreach var of varlist gdp_growth trade_gdp investment inflation {
    twoway (line `var' year, lcolor(blue)) ///
           (line `var'_ma3 year, lcolor(red) lpattern(dash)) ///
           (scatter `var' year if year == 1980, mlabel(year) msymbol(D)) ///
           (scatter `var' year if year == 2001, mlabel(year) msymbol(D)), ///
           title("`var' Over Time with Key Events", size(medium)) ///
           subtitle("With 3-year Moving Average") ///
           xtitle("Year") ytitle("`var'") ///
           xline(1980 2001, lpattern(dash) lcolor(gray)) ///
           legend(order(1 "Actual" 2 "3-year MA" 3 "Liberalization" 4 "2001 Crisis")) ///
           note("Source: World Bank WDI") ///
           graphregion(color(white)) bgcolor(white) ///
           ylabel(, angle(horizontal)) ///
           saving("output/`var'_advanced_trend.gph", replace)
    graph export "output/`var'_advanced_trend.png", replace
}

* Create combined plot for trade components
twoway (line trade_gdp year, lcolor(blue)) ///
       (line exports_gdp year, lcolor(green)) ///
       (line imports_gdp year, lcolor(red)), ///
       title("Trade Components Over Time", size(medium)) ///
       xtitle("Year") ytitle("% of GDP") ///
       legend(order(1 "Total Trade" 2 "Exports" 3 "Imports")) ///
       note("Source: World Bank WDI") ///
       graphregion(color(white)) bgcolor(white) ///
       ylabel(, angle(horizontal)) ///
       saving("output/trade_components.gph", replace)
graph export "output/trade_components.png", replace

* Correlation matrix visualization
* Using standard correlation matrix instead of heatmap
correlate gdp_growth trade_gdp investment inflation govt_exp tertiary_educ
matrix C = r(C)
matrix list C

* Save correlation matrix to CSV
putexcel set "output/correlation_matrix.xlsx", replace
putexcel A1 = matrix(C), names

********************************************************************************
* 4. Advanced Statistical Analysis
********************************************************************************
* Stationarity tests
foreach var of varlist gdp_growth trade_gdp investment inflation govt_exp tertiary_educ {
    dfuller `var', trend
}

* Granger causality tests
varsoc gdp_growth trade_gdp, maxlag(4)
var gdp_growth trade_gdp, lags(1/2)
vargranger

********************************************************************************
* 5. Advanced Regression Analysis
********************************************************************************
* Generate standardized variables for better coefficient interpretation
foreach var of varlist gdp_growth trade_gdp investment inflation govt_exp tertiary_educ {
    egen std_`var' = std(`var')
}

* Model 1: Basic model with standardized variables
eststo clear
eststo: reg std_gdp_growth std_trade_gdp std_investment std_inflation std_govt_exp std_tertiary_educ, robust

* Model 2: With period controls
eststo: reg std_gdp_growth std_trade_gdp std_investment std_inflation std_govt_exp std_tertiary_educ ///
    i.period2 i.period3, robust

* Model 3: With interactions
eststo: reg std_gdp_growth c.std_trade_gdp##c.std_investment c.std_trade_gdp##c.std_tertiary_educ ///
    std_inflation std_govt_exp i.period2 i.period3, robust

* Model 4: With squared terms
eststo: reg std_gdp_growth c.std_trade_gdp##c.std_trade_gdp std_investment std_inflation ///
    std_govt_exp std_tertiary_educ i.period2 i.period3, robust

* Export regression results
esttab using "output/advanced_regression_results.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Advanced Regression Results") ///
    mtitles("Basic" "With Periods" "Interactions" "Non-linear") ///
    stats(N r2_a F p ll aic bic) ///
    note("* p<0.10, ** p<0.05, *** p<0.01") ///
    addnotes("All variables are standardized")

********************************************************************************
* 6. Diagnostic Tests
********************************************************************************
* Run a version of the model without robust SE for diagnostic tests
quietly reg std_gdp_growth std_trade_gdp std_investment std_inflation std_govt_exp std_tertiary_educ

* Residual analysis
predict resid, residuals
predict yhat, xb

* Normality test
sktest resid

* Heteroskedasticity tests
estat hettest
estat imtest, white

* Plot residuals
twoway (scatter resid yhat) (lowess resid yhat), ///
    title("Residual Plot") ytitle("Residuals") xtitle("Fitted values") ///
    graphregion(color(white)) bgcolor(white) ///
    saving("output/residual_plot.gph", replace)
graph export "output/residual_plot.png", replace

* QQ plot
qnorm resid, title("Q-Q Plot of Residuals") ///
    graphregion(color(white)) bgcolor(white) ///
    saving("output/qq_plot.gph", replace)
graph export "output/qq_plot.png", replace

* Additional diagnostic plots
* Residuals vs. predictors
foreach var of varlist std_trade_gdp std_investment std_inflation std_govt_exp std_tertiary_educ {
    twoway (scatter resid `var') (lowess resid `var'), ///
        title("Residuals vs. `var'") ///
        ytitle("Residuals") xtitle("`var'") ///
        graphregion(color(white)) bgcolor(white) ///
        saving("output/resid_`var'_plot.gph", replace)
    graph export "output/resid_`var'_plot.png", replace
}

* Return to robust regression for further analysis
quietly reg std_gdp_growth std_trade_gdp std_investment std_inflation std_govt_exp std_tertiary_educ, robust

********************************************************************************
* 7. Marginal Effects Analysis
********************************************************************************
* Calculate and plot marginal effects
margins, dydx(std_trade_gdp) at(std_investment=(-2(1)2))
marginsplot, title("Marginal Effect of Trade on Growth") ///
    subtitle("At Different Levels of Investment") ///
    saving("output/marginal_effects.gph", replace)
graph export "output/marginal_effects.png", replace

********************************************************************************
* 8. Export Summary Tables
********************************************************************************
* Create LaTeX tables for publication
eststo clear
eststo: reg std_gdp_growth std_trade_gdp std_investment std_inflation std_govt_exp std_tertiary_educ, robust
eststo: reg std_gdp_growth c.std_trade_gdp##c.std_investment c.std_trade_gdp##c.std_tertiary_educ ///
    std_inflation std_govt_exp, robust

esttab using "output/regression_tables.tex", replace ///
    style(tex) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Regression Results") ///
    label booktabs ///
    alignment(D{.}{.}{-1}) ///
    addnotes("All variables are standardized")

* Close log file
log close 