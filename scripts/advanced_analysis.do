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
    label variable std_`var' "Standardized `var'"
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
* 7. Improved Marginal Effects Analysis
********************************************************************************
* Load the main dataset and recreate all necessary variables
use "data/turkey_macro_data.dta", clear
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

* Regenerate standardized variables
foreach var of varlist gdp_growth trade_gdp investment inflation govt_exp tertiary_educ {
    egen std_`var' = std(`var')
    label variable std_`var' "Standardized `var'"
}

* Center variables for interaction analysis
foreach var of varlist trade_gdp investment {
    sum `var'
    gen c_`var' = `var' - r(mean)
}

* Generate interaction term explicitly
gen c_trade_inv_int = c_trade_gdp * c_investment

* Estimate improved model with centered variables
reg gdp_growth c_trade_gdp c_investment c_trade_inv_int inflation govt_exp tertiary_educ i.period2 i.period3, robust

* Store coefficients for marginal effects calculation
local b_trade = _b[c_trade_gdp]
local b_int = _b[c_trade_inv_int]

* Generate range of investment values for marginal effects
preserve
drop if missing(c_investment)
sum c_investment
local min_inv = r(min)
local max_inv = r(max)

tempname memhold
postfile `memhold' inv_level marg_effect se_marg using "output/marginal_effects.dta", replace

forvalues inv = -2(0.25)2 {
    * Calculate marginal effect
    local marg = `b_trade' + `b_int' * `inv'
    
    * Calculate standard error of marginal effect
    lincom c_trade_gdp + `inv' * c_trade_inv_int
    
    post `memhold' (`inv') (`marg') (r(se))
}
postclose `memhold'
restore

* Create marginal effects plot
preserve
use "output/marginal_effects.dta", clear

* Generate confidence intervals
gen ci_upper = marg_effect + 1.96 * se_marg
gen ci_lower = marg_effect - 1.96 * se_marg

* Create enhanced marginal effects plot
twoway (line marg_effect inv_level, lcolor(navy) lwidth(medthick)) ///
       (rarea ci_lower ci_upper inv_level, color(navy%20)) , ///
    title("Marginal Effect of Trade on Growth", size(medium)) ///
    subtitle("At Different Levels of Investment", size(small)) ///
    xlabel(-2(0.5)2, angle(0)) ///
    ylabel(, angle(0)) ///
    xtitle("Standardized values of Investment", size(small)) ///
    ytitle("Marginal Effect of Trade on Growth", size(small)) ///
    yline(0, lpattern(dash) lcolor(gray)) ///
    graphregion(color(white)) bgcolor(white) ///
    legend(off) ///
    note("Note: Dashed line at zero. Shaded area shows 95% confidence intervals.") ///
    saving("output/improved_marginal_effects.gph", replace)
graph export "output/improved_marginal_effects.png", replace
restore

* Additional diagnostic for interaction effect
reg gdp_growth c_trade_gdp c_investment c_trade_inv_int ///
    inflation govt_exp tertiary_educ i.period2 i.period3, robust

* Test joint significance of trade variables
test c_trade_gdp c_trade_inv_int

* Calculate standardized coefficients
quietly sum gdp_growth
local sd_y = r(sd)
foreach var of varlist c_trade_gdp c_investment c_trade_inv_int inflation govt_exp tertiary_educ {
    quietly sum `var'
    local sd_`var' = r(sd)
    local b_`var' = _b[`var']
    local beta_`var' = `b_`var'' * `sd_`var'' / `sd_y'
}

* Display standardized coefficients
di "Standardized coefficients:"
foreach var of varlist c_trade_gdp c_investment c_trade_inv_int inflation govt_exp tertiary_educ {
    di "`var': " %6.4f `beta_`var''
}

* Export standardized coefficients to file
file open beta_out using "output/standardized_coefficients.txt", write replace
file write beta_out "Variable,Standardized Coefficient" _n
foreach var of varlist c_trade_gdp c_investment c_trade_inv_int inflation govt_exp tertiary_educ {
    file write beta_out "`var'," %6.4f (`beta_`var'') _n
}
file close beta_out

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

********************************************************************************
* 9. Advanced Time Series Analysis
********************************************************************************
* ARIMA Modeling
* Determine optimal ARIMA specification using information criteria
tsset year
arima gdp_growth, arima(1,0,1)
estat ic
arima gdp_growth, arima(2,0,2)
estat ic
arima gdp_growth, arima(1,1,1)
estat ic

* Fit the best ARIMA model (example with ARIMA(1,0,1))
arima gdp_growth trade_gdp investment inflation, arima(1,0,1)
predict arima_resid, residuals
predict arima_forecast, dynamic(2020)

* Plot actual vs. fitted values
twoway (line gdp_growth year) (line arima_forecast year if year >= 2020), ///
    title("ARIMA Forecast of GDP Growth") ///
    legend(order(1 "Actual" 2 "Forecast")) ///
    graphregion(color(white)) bgcolor(white) ///
    saving("output/arima_forecast.gph", replace)
graph export "output/arima_forecast.png", replace

********************************************************************************
* 10. Cointegration Analysis
********************************************************************************
* Test for unit roots in levels and first differences
foreach var of varlist gdp_growth trade_gdp investment {
    dfuller `var', trend
    dfuller D.`var', trend
}

* Johansen cointegration test
vecrank gdp_growth trade_gdp investment, trend(constant) lags(2)
vec gdp_growth trade_gdp investment, trend(constant) lags(2) rank(1)

* Error Correction Model (ECM)
* Generate lagged variables and first differences
foreach var of varlist gdp_growth trade_gdp investment {
    gen D_`var' = D.`var'
    gen L_`var' = L.`var'
}

* Estimate ECM
reg D_gdp_growth L_gdp_growth L_trade_gdp L_investment ///
    D_trade_gdp D_investment, robust

********************************************************************************
* 11. Time Series Panel Analysis
********************************************************************************
* Set time dimension
tsset year

* Time-series regression with Newey-West standard errors
newey gdp_growth trade_gdp investment inflation i.period2 i.period3, lag(2)
estimates store ts_model1

* Auto-regressive distributed lag model (ARDL)
reg gdp_growth L(1/2).gdp_growth L(0/2).(trade_gdp investment inflation) ///
    i.period2 i.period3, robust
estimates store ts_model2

* Test for serial correlation (run regular regression first)
quietly reg gdp_growth trade_gdp investment inflation i.period2 i.period3
* Durbin's alternative test for autocorrelation
estat durbinalt
* Breusch-Godfrey LM test for autocorrelation
estat bgodfrey, lags(1 2 4)

* Run regression with Newey-West standard errors if serial correlation is present
newey gdp_growth trade_gdp investment inflation i.period2 i.period3, lag(4)

* Test for ARCH effects (need to run without robust for this test)
quietly reg gdp_growth trade_gdp investment inflation i.period2 i.period3
estat archlm, lags(1 2 4)

* Save the current dataset
save "data/analysis_temp.dta", replace

* Rolling window regression
preserve
tempfile results
gen b_trade = .
gen se_trade = .
local window = 15  // 15-year rolling window

forvalues t = 1/`=_N-`window'' {
    reg gdp_growth trade_gdp investment inflation ///
        if _n >= `t' & _n <= `t'+`window', robust
    replace b_trade = _b[trade_gdp] in `=`t'+`window''
    replace se_trade = _se[trade_gdp] in `=`t'+`window''
}

* Generate confidence intervals
gen upper_ci = b_trade + 1.96*se_trade
gen lower_ci = b_trade - 1.96*se_trade

* Plot rolling coefficients
twoway (line b_trade year if !missing(b_trade), lcolor(navy)) ///
       (line upper_ci year if !missing(upper_ci), lpattern(dash) lcolor(gray)) ///
       (line lower_ci year if !missing(lower_ci), lpattern(dash) lcolor(gray)), ///
    title("Rolling Window Estimates: Trade Effect on Growth", size(medium)) ///
    subtitle("15-year rolling window", size(small)) ///
    xtitle("End Year of Rolling Window") ytitle("Coefficient Estimate") ///
    legend(order(1 "Coefficient" 2 "95% CI")) ///
    note("Note: Dashed lines represent 95% confidence intervals") ///
    graphregion(color(white)) bgcolor(white) ///
    saving("output/rolling_coefficients.gph", replace)
graph export "output/rolling_coefficients.png", replace
restore

* Load back the saved dataset to ensure consistency
use "data/analysis_temp.dta", clear

* Export results
estout ts_model1 ts_model2 using "output/time_series_results.tex", replace ///
    style(tex) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    legend label varlabels(_cons constant) ///
    title("Time Series Analysis Results") ///
    prehead("\begin{table}[htbp]\centering\caption{Time Series Analysis Results}\label{tab:tsresults}\begin{tabular}{lcc}") ///
    postfoot("\end{tabular}\end{table}")

********************************************************************************
* 12. Advanced Robustness Checks
********************************************************************************
* Quantile Regression
qreg gdp_growth trade_gdp investment inflation, quantile(0.25)
estimates store q25
qreg gdp_growth trade_gdp investment inflation, quantile(0.5)
estimates store q50
qreg gdp_growth trade_gdp investment inflation, quantile(0.75)
estimates store q75

* Export quantile regression results
estout q25 q50 q75 using "output/quantile_results.tex", replace ///
    style(tex) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    legend label varlabels(_cons constant) ///
    title("Quantile Regression Results") ///
    prehead("\begin{table}[htbp]\centering\caption{Quantile Regression Analysis}\label{tab:qreg}\begin{tabular}{lccc}") ///
    postfoot("\end{tabular}\end{table}")

* Structural Break Tests
* Chow Test
reg gdp_growth trade_gdp investment inflation if year < 2001
scalar rss1 = e(rss)
reg gdp_growth trade_gdp investment inflation if year >= 2001
scalar rss2 = e(rss)
reg gdp_growth trade_gdp investment inflation
scalar rss = e(rss)
scalar f_stat = ((rss - (rss1 + rss2))/4)/((rss1 + rss2)/(e(N)-8))
scalar p_value = 1 - F(4, e(N)-8, f_stat)

* Quandt Likelihood Ratio (QLR) Test
rolling _b, window(20) recursive: reg gdp_growth trade_gdp investment inflation

********************************************************************************
* 13. Non-linear and Threshold Effects
********************************************************************************
* Load the main dataset
use "data/turkey_macro_data.dta", clear
tsset year

* Drop any existing generated variables to avoid conflicts
foreach var in med_trade high_trade trade_gdp_sq trade_gdp_cube {
    capture drop `var'
}

* Generate threshold variables
egen med_trade = median(trade_gdp)
gen high_trade = (trade_gdp > med_trade)

* Threshold regression
reg gdp_growth c.trade_gdp##i.high_trade investment inflation, robust

* Generate polynomial terms and interactions
generate double trade_gdp_sq = trade_gdp^2
generate double trade_gdp_cube = trade_gdp^3

* Label polynomial terms
label variable trade_gdp_sq "Trade/GDP squared"
label variable trade_gdp_cube "Trade/GDP cubed"

* Non-linear regression
reg gdp_growth c.trade_gdp##c.trade_gdp##c.trade_gdp investment inflation, robust

* Save dataset for next section
save "data/analysis_temp.dta", replace

********************************************************************************
* 14. Advanced Causality Analysis
********************************************************************************
* Granger Causality with Multiple Lags
varsoc gdp_growth trade_gdp investment, maxlag(8)
var gdp_growth trade_gdp investment, lags(1/4)
vargranger

* Impulse Response Functions
* Create IRF (no need to drop first since it doesn't exist yet)
irf create order1, step(8) set(myirf, replace)
irf graph irf, response(gdp_growth) impulse(trade_gdp)
graph export "output/irf_trade_growth.png", replace

* Forecast Error Variance Decomposition
irf table fevd, response(gdp_growth) impulse(trade_gdp investment)

********************************************************************************
* 15. Export Final Results
********************************************************************************
* Create comprehensive LaTeX tables
* Export time series results
estout ts_model1 ts_model2 using "output/time_series_results.tex", replace ///
    style(tex) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    legend label varlabels(_cons constant) ///
    title("Time Series Analysis Results") ///
    prehead("\begin{table}[htbp]\centering\caption{Time Series Analysis Results}\label{tab:tsresults}\begin{tabular}{lcc}") ///
    postfoot("\end{tabular}\end{table}")

* Export quantile regression results
estout q25 q50 q75 using "output/quantile_results.tex", replace ///
    style(tex) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    legend label varlabels(_cons constant) ///
    title("Quantile Regression Results") ///
    prehead("\begin{table}[htbp]\centering\caption{Quantile Regression Analysis}\label{tab:qreg}\begin{tabular}{lccc}") ///
    postfoot("\end{tabular}\end{table}")

* Export non-linear model results
eststo clear
quietly reg gdp_growth c.trade_gdp##c.trade_gdp##c.trade_gdp investment inflation, robust
eststo: estimates store nl_model

esttab nl_model using "output/nonlinear_results.tex", replace ///
    style(tex) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    legend label varlabels(_cons constant) ///
    title("Non-linear Analysis Results") ///
    prehead("\begin{table}[htbp]\centering\caption{Non-linear Trade Effects}\label{tab:nonlinear}\begin{tabular}{lc}") ///
    postfoot("\end{tabular}\end{table}")

* Close log file
log close 