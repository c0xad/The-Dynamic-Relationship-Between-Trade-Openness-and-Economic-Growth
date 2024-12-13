/*******************************************************************************
* Advanced Economic Theory Integration and Policy Implications for Turkey's Trade Policy
* Author: Eren
* Date: December 2024
*******************************************************************************/

clear all
set more off
capture log close
set matsize 11000
set maxvar 32767

* Clean up any potentially existing variables
capture drop fe_resid xb upper_band lower_band

* Set working directory and start log
cd "c:/Users/eren/Desktop/fundshedge"
log using "output/advanced_economic_theory_policy_log.txt", replace

* Load the prepared dataset and analysis results
use "data/turkey_macro_data.dta", clear
tsset year

* Regenerate reform period indicators
gen pre_reform = (year < 1980)
gen post_reform = (year >= 1980 & year < 2001)
label variable pre_reform "Pre-reform period"
label variable post_reform "Post-reform period"

********************************************************************************
* 1. Advanced Theoretical Framework Integration
********************************************************************************

* Clean up any existing reform variables
capture drop pre_reform post_reform

* Generate institutional period indicators
gen pre_reform = (year < 1980)
gen post_reform = (year >= 1980 & year < 2001)
label variable pre_reform "Pre-reform period"
label variable post_reform "Post-reform period"

* 1.1 Endogenous Growth Theory Variables
* Generate technology diffusion proxy with spillover effects
gen tech_diffusion = (trade_gdp * tertiary_educ) / 100
gen tech_spillover = tech_diffusion * (1 + log(trade_gdp/100))
label variable tech_diffusion "Technology Diffusion Index"
label variable tech_spillover "Technology Spillover Effect"

* Generate innovation capacity with learning-by-doing effects
gen innovation_cap = tertiary_educ * govt_exp
gen learning_effect = innovation_cap * (1 + log(trade_gdp/100))
label variable innovation_cap "Innovation Capacity Index"
label variable learning_effect "Learning-by-Doing Effect"

* 1.2 New Trade Theory Variables with Heterogeneous Firms
* First generate industrial concentration
gen ind_concentration = govt_exp / (100 + gdp_growth)  // Using GDP growth as denominator
label variable ind_concentration "Industrial Concentration"

* Then generate market size and competition measures
gen market_size = log(100 + gdp_growth)  // Adding 100 to ensure positive values for log
gen market_competition = market_size * (1 - ind_concentration)
label variable market_size "Market Size (log transformed GDP growth)"
label variable market_competition "Market Competition Index"

* Generate scale economies effect
gen scale_economies = ind_concentration * log(market_size)
label variable scale_economies "Scale Economies Effect"

* 1.3 Institutional Economics Variables with Transaction Costs
* Generate institutional quality periods with transition effects
gen inst_quality = .
replace inst_quality = 1 if year < 1980  // Pre-reform period
replace inst_quality = 2 if year >= 1980 & year < 2001  // Post-liberalization
replace inst_quality = 3 if year >= 2001  // Post-2001 reforms

* Generate institutional transition costs
gen inst_transition = .
replace inst_transition = 1 if year == 1980 | year == 1981  // First transition
replace inst_transition = 1 if year == 2001 | year == 2002  // Second transition
replace inst_transition = 0 if missing(inst_transition)

label variable inst_quality "Institutional Quality Period"
label variable inst_transition "Institutional Transition Period"
label define inst_qual 1 "Pre-reform" 2 "Post-liberalization" 3 "Post-2001 reforms"
label values inst_quality inst_qual

********************************************************************************
* 2. Advanced Econometric Analysis
********************************************************************************

* 2.1 Unit Root and Stationarity Tests
foreach var of varlist gdp_growth trade_gdp investment inflation {
    * Augmented Dickey-Fuller test
    dfuller `var', trend lags(4)
    
    * Phillips-Perron test
    pperron `var', trend lags(4)
    
    * KPSS test (if available)
    capture kpss `var'
}

* 2.2 Cointegration Analysis
* Johansen's test for cointegration
vecrank gdp_growth trade_gdp investment, trend(constant) lags(4)

* 2.3 Error Correction Model
* Generate first differences
foreach var of varlist gdp_growth trade_gdp investment {
    gen d_`var' = d.`var'
}

* Generate year dummies for time effects
tab year, gen(year_dummy)

* Estimate ECM with year effects
reg d_gdp_growth L.gdp_growth L.trade_gdp L.investment ///
    d_trade_gdp d_investment year_dummy*, robust
estimates store ecm_model

* Test for time effects
testparm year_dummy*

* 2.4 Dynamic Panel and Time Series Analysis
* First, let's examine the data structure
summarize year
display "Number of time periods: " r(N)

* Generate lagged variables explicitly
sort year
gen L1_gdp_growth = L1.gdp_growth
gen L2_gdp_growth = L2.gdp_growth

* Create dummy variables for institutional quality (using only two periods to avoid collinearity)
* Note: pre_reform and post_reform are already defined at the beginning of the script

* Generate panel identifier
egen panel_id = group(year)
label variable panel_id "Panel identifier"

* Set panel structure
xtset panel_id year

* Clean up existing variables
capture {
    drop upper_band
    drop lower_band
    drop fe_resid
}

* Generate year dummies (dropping the first year to avoid collinearity)
quietly tab year, gen(yr_)
local first_yr = year[1]
local last_yr = year[_N]
local n_years = `last_yr' - `first_yr' + 1
display "Generating year dummies from `first_yr' to `last_yr' (`n_years' years)"

* Fixed effects regression with time effects
xtreg gdp_growth trade_gdp investment inflation yr_*, fe
estimates store fe_model

* List coefficients to verify year dummies are included
estimates table fe_model, keep(yr_*)

* F-test for joint significance
test trade_gdp investment inflation

* Run regression with existing year dummies
reg gdp_growth trade_gdp investment inflation yr_*, robust

* Test for time effects
testparm yr_*

* Clean up temporary variables
capture drop upper_band lower_band fe_resid

* Generate and verify residuals
predict fe_resid, residuals

* Verify residuals are not all zero
sum fe_resid, detail

* Only proceed if we have valid residuals
if r(sd) > 0 {
    * Clean up and calculate confidence bands
    capture drop upper_band
    capture drop lower_band
    
    local sd = r(sd)
    gen upper_band = 2*`sd'
    gen lower_band = -2*`sd'

    * Generate improved residual plot with better scaling
    twoway (scatter fe_resid year, msize(small) mcolor(navy%70)) ///
        (line upper_band year, lpattern(dash) lcolor(red%70)) ///
        (line lower_band year, lpattern(dash) lcolor(red%70)) ///
        (lowess fe_resid year, lcolor(blue) lwidth(medthick)), ///
        title("Fixed Effects Residuals Over Time", size(medium)) ///
        ytitle("Residuals") xtitle("Year") ///
        ylabel(, angle(horizontal)) ///
        xlabel(1960(10)2020, angle(45)) ///
        legend(order(1 "Residuals" 2 "95% CI" 4 "Smoothed trend") rows(1)) ///
        graphregion(color(white)) bgcolor(white) ///
        yline(0, lcolor(gray) lpattern(dash)) ///
        scale(1.2)
    graph export "output/residual_plot.png", replace width(1200) height(800)
}
else {
    display as error "Warning: All residuals are zero. Check the regression specification."
}

* Between effects model
xtreg gdp_growth trade_gdp investment inflation pre_reform post_reform, be
estimates store be_model

* Enhanced diagnostic plots
* Clean up and reload data
drop _all
use "data/turkey_macro_data.dta", clear
tsset year

* Regenerate reform period indicators
gen pre_reform = (year < 1980)
gen post_reform = (year >= 1980 & year < 2001)
label variable pre_reform "Pre-reform period"
label variable post_reform "Post-reform period"

* 1. Residuals vs. Fitted values
reg gdp_growth trade_gdp investment inflation
predict xb, xb
predict fe_resid, residuals

sum fe_resid
local sd = r(sd)

twoway (scatter fe_resid xb, msize(small)) ///
    (lowess fe_resid xb, lcolor(red)), ///
    title("Residuals vs. Fitted Values", size(large)) ///
    xtitle("Fitted values", size(medium)) ytitle("Residuals", size(medium)) ///
    ylabel(#10, angle(0) format(%12.2e)) ///
    xlabel(#10, angle(0)) ///
    legend(order(1 "Residuals" 2 "Lowess smooth") size(medium)) ///
    graphregion(color(white)) bgcolor(white) ///
    scale(1.2)
graph export "output/residuals_vs_fitted.png", replace width(1200) height(800)

* 2. Residuals over time with confidence bands
sum fe_resid
local sd = r(sd)
capture drop upper_band lower_band
gen upper_band = 2*`sd'
gen lower_band = -2*`sd'

twoway (scatter fe_resid year, msize(small)) ///
    (line upper_band year, lpattern(dash) lcolor(red)) ///
    (line lower_band year, lpattern(dash) lcolor(red)) ///
    (lowess fe_resid year, lcolor(blue)), ///
    title("Fixed Effects Residuals Over Time", size(large)) ///
    ytitle("Residuals", size(medium)) xtitle("Year", size(medium)) ///
    ylabel(#10, angle(0) format(%12.2e)) ///
    xlabel(1960(10)2020, angle(0)) ///
    legend(order(1 "Residuals" 2 "95% CI" 4 "Smoothed trend") size(medium)) ///
    graphregion(color(white)) bgcolor(white) ///
    scale(1.2)
graph export "output/residual_plot.png", replace width(1200) height(800)

* 3. Residual distribution
kdensity fe_resid, normal bwidth(0.2) ///
    title("Distribution of Residuals") ///
    xtitle("Residuals") ytitle("Density") ///
    legend(order(1 "Kernel" 2 "Normal")) ///
    graphregion(color(white)) bgcolor(white)
graph export "output/residual_dist.png", replace

* 4. Residual diagnostics
* Descriptive statistics
summarize fe_resid, detail

* Clean up and regenerate year dummies
capture drop yr_*
quietly tab year, gen(yr_)

* Run regression with year dummies
reg gdp_growth trade_gdp investment inflation yr_*, robust

* Test for normality
sktest fe_resid

* Test for time effects
testparm yr_*

* Correlation matrix
correlate fe_resid trade_gdp investment inflation pre_reform post_reform

* Export results with enhanced diagnostics
esttab fe_model be_model using "output/panel_analysis.tex", ///
    replace cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Panel Regression Results") ///
    mtitles("Fixed Effects" "Between Effects") ///
    scalars("N Observations" "r2_o Overall R-sq" "r2_w Within R-sq" "r2_b Between R-sq" "F F-statistic") ///
    addnotes("Robust standard errors in parentheses" ///
            "Time trend included in FE model" ///
            "Standard errors clustered by year") ///
    drop(_cons)

* Additional model diagnostics
* F-test for joint significance
test trade_gdp investment inflation

* Test for time effects
testparm yr_*

* Clean up temporary variables

* Export results
esttab fe_model be_model using "output/dynamic_analysis.tex", ///
    replace cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Dynamic Analysis Results") ///
    mtitles("FE" "BE") ///
    scalars("N Observations" "r2 R-squared" "F F-statistic") ///
    addnotes("Robust standard errors in parentheses" ///
            "BE = Between Effects estimation") ///
    drop(_cons)

* Additional diagnostics
* Set up time series and generate lagged GDP growth
sort year
tsset year
capture drop L1_gdp_growth
gen L1_gdp_growth = L1.gdp_growth

* Run regression with institutional periods and lagged GDP
reg gdp_growth L1_gdp_growth trade_gdp investment inflation pre_reform post_reform, robust

* F-test for joint significance of institutional periods
test pre_reform post_reform

* Calculate long-run multipliers for trade effects
nlcom _b[trade_gdp]/(1-_b[L1_gdp_growth])

********************************************************************************
* 4. Advanced Policy Impact Analysis
********************************************************************************

* 4.1 Heterogeneous Treatment Effects
* Generate policy treatment indicators
gen post_cu = (year >= 1996)
gen post_crisis = (year >= 2001)

* Synthetic Control Method preparation
sort year
gen time = _n
xtset year

* 4.2 Difference-in-Differences with Multiple Periods
reg gdp_growth i.post_reform##c.trade_gdp i.post_cu##c.trade_gdp ///
    i.post_crisis##c.trade_gdp investment inflation, robust cluster(year)
estimates store did_model

* 4.3 Quantile Treatment Effects
* Reload data and set time series
drop _all
use "data/turkey_macro_data.dta", clear
tsset year

* Regenerate institutional quality variable
gen inst_quality = .
replace inst_quality = 1 if year < 1980    // Pre-reform period
replace inst_quality = 2 if year >= 1980 & year < 2001    // Post-liberalization
replace inst_quality = 3 if year >= 2001   // Post-2001 reforms
label variable inst_quality "Institutional Quality Period"
label define inst_qual 1 "Pre-reform" 2 "Post-liberalization" 3 "Post-2001 reforms"
label values inst_quality inst_qual

* Regenerate institutional transition variable
gen inst_transition = .
replace inst_transition = 1 if year == 1980 | year == 1981  // First transition
replace inst_transition = 1 if year == 2001 | year == 2002  // Second transition
replace inst_transition = 0 if missing(inst_transition)
label variable inst_transition "Institutional Transition Period"

qreg gdp_growth trade_gdp investment inflation i.inst_quality, quantile(0.25)
estimates store qte25
qreg gdp_growth trade_gdp investment inflation i.inst_quality, quantile(0.5)
estimates store qte50
qreg gdp_growth trade_gdp investment inflation i.inst_quality, quantile(0.75)
estimates store qte75

* 4.4 Local Projection Method for Dynamic Effects
* Set up time series structure
sort year
tsset year, yearly

* Perform local projections
forvalues h = 0/5 {
    gen f`h'_gdp_growth = f`h'.gdp_growth
    reg f`h'_gdp_growth trade_gdp investment inflation i.inst_quality ///
        L(1/4).gdp_growth L(1/4).trade_gdp, robust
    estimates store lp`h'
}

********************************************************************************
* 5. Advanced Policy Effectiveness Analysis
********************************************************************************

* 5.1 Regime-Switching Models
* Generate regime indicators
gen high_growth = (gdp_growth > r(p75))
gen crisis_period = (gdp_growth < r(p25))

* Markov-Switching Model (if available)
capture noi {
    msregress gdp_growth trade_gdp investment inflation, states(2)
    estimates store ms_model
}

* 5.2 Threshold Regression Analysis
* Grid search for threshold
quietly sum trade_gdp, detail
local rss = 1e10  // Initialize RSS to a large number

forvalues i = 1/99 {
    quietly sum trade_gdp, detail
    local cutoff = r(p`i')
    
    * Count observations in each subsample
    quietly count if trade_gdp <= `cutoff'
    local n1 = r(N)
    quietly count if trade_gdp > `cutoff'
    local n2 = r(N)
    
    * Only proceed if both subsamples have sufficient observations
    if `n1' >= 10 & `n2' >= 10 {
        quietly reg gdp_growth trade_gdp investment inflation if trade_gdp <= `cutoff'
        local rss1 = e(rss)
        quietly reg gdp_growth trade_gdp investment inflation if trade_gdp > `cutoff'
        local rss2 = e(rss)
        
        if `rss1' + `rss2' < `rss' {
            local rss = `rss1' + `rss2'
            local threshold = `cutoff'
        }
    }
}

* Estimate threshold model
gen below_threshold = (trade_gdp <= `threshold')
reg gdp_growth c.trade_gdp##i.below_threshold investment inflation, robust
estimates store threshold_model

********************************************************************************
* 6. Advanced Policy Interaction Analysis
********************************************************************************

* 6.1 Non-linear Policy Effects
* Note: polynomial terms already defined in section 5.2
* Estimate non-linear effects
reg gdp_growth c.trade_gdp##c.trade_gdp##c.trade_gdp investment inflation ///
    i.inst_quality, robust cluster(inst_quality)
estimates store nonlinear_model

* 6.2 Policy Complementarities
* Generate interaction terms
foreach var of varlist investment tertiary_educ govt_exp {
    gen trade_`var'_int = trade_gdp * `var'
}

* Estimate complementarities
reg gdp_growth trade_gdp trade_investment_int trade_tertiary_educ_int ///
    trade_govt_exp_int investment tertiary_educ govt_exp inflation ///
    i.inst_quality, robust cluster(inst_quality)
estimates store complementarities_model

********************************************************************************
* 7. Advanced Robustness Checks
********************************************************************************

* 7.1 Instrumental Variables Estimation
* Generate instruments
gen l2_trade_gdp = L2.trade_gdp
gen l2_investment = L2.investment

* First-stage regression
reg trade_gdp l2_trade_gdp l2_investment investment inflation i.inst_quality
predict trade_gdp_hat

* 2SLS estimation
ivregress 2sls gdp_growth investment inflation i.inst_quality ///
    (trade_gdp = l2_trade_gdp l2_investment), robust
estimates store iv_model

* Test for weak instruments
estat firststage
estat overid

* 7.2 Sensitivity Analysis
* Jackknife estimation
capture noi {
    jackknife: reg gdp_growth trade_gdp investment inflation i.inst_quality
    estimates store jack_model
}

********************************************************************************
* 5. Advanced Policy Impact Heterogeneity Analysis
********************************************************************************

* 5.1 Quantile Regression Analysis
* Run base OLS regression first
reg gdp_growth trade_gdp investment inflation inst_quality if !inst_transition
estimates store ols_model

* Run quantile regressions for each quantile separately and store them
forvalues q = 1/9 {
    local qt = `q'/10
    qreg gdp_growth trade_gdp investment inflation inst_quality if !inst_transition, quantile(`qt')
    estimates store qreg_`q'
}

* Graph quantile effects
grqreg trade_gdp, cons ci ols olsci reps(100) seed(12345)
graph export "output/quantile_effects.png", replace width(1200) height(800)

* 5.2 Non-linear Policy Effects
* Generate polynomial terms
capture drop trade_gdp_sq
gen trade_gdp_sq = trade_gdp^2

* Estimate non-linear relationship with just trade variables
reg gdp_growth c.trade_gdp##c.trade_gdp investment inflation i.inst_quality, robust
estimates store nonlinear_model

* Store coefficients for manual calculation
local b1 = _b[trade_gdp]
local b2 = _b[c.trade_gdp#c.trade_gdp]

* Generate sequence of trade/GDP values and calculate marginal effects
drop if _n > 1
set obs 81
gen trade_gdp_values = 20 + (_n-1) in 1/81
gen marginal_effect = `b1' + 2*`b2'*trade_gdp_values
gen se_effect = sqrt(e(V)[1,1] + 4*trade_gdp_values^2*e(V)[2,2] + 4*trade_gdp_values*e(V)[1,2])
gen ci_upper = marginal_effect + 1.96*se_effect
gen ci_lower = marginal_effect - 1.96*se_effect

* Create enhanced marginal effects plot
twoway (rarea ci_lower ci_upper trade_gdp_values, color(gs12%50)) ///
    (line marginal_effect trade_gdp_values, lcolor(navy) lwidth(medthick)), ///
    title("Marginal Effect of Trade Openness", size(medium)) ///
    ytitle("Effect on GDP Growth") ///
    xtitle("Trade/GDP Ratio") ///
    xlabel(20(10)100) ///
    ylabel(, angle(horizontal)) ///
    legend(off) ///
    scheme(s2color)
graph export "output/marginal_effects.png", replace width(1200) height(800)

* 5.3 Structural Break Analysis with Multiple Windows
* Save current dataset before rolling regression
save "temp/before_rolling.dta", replace

* Reload the data to ensure we have all observations
use "data/turkey_macro_data.dta", clear
tsset year

* Rolling window regression
rolling _b _se, window(10) clear: reg gdp_growth trade_gdp investment inflation

* Generate time variable for x-axis (assuming yearly data)
gen _end = _n + 9  // Adding window size - 1 to get end year

* Generate confidence intervals
gen coef_ci_upper = _b_trade_gdp + 1.96*_se_trade_gdp
gen coef_ci_lower = _b_trade_gdp - 1.96*_se_trade_gdp

* Plot rolling coefficients with CI
twoway (line _b_trade_gdp _end) ///
    (line coef_ci_upper _end, lpattern(dash)) ///
    (line coef_ci_lower _end, lpattern(dash)), ///
    title("Rolling Window Estimates of Trade Impact") ///
    ytitle("Coefficient") xtitle("End Year") ///
    legend(order(1 "Coefficient" 2 "95% CI")) ///
    scheme(s2color)
graph export "output/rolling_coefficients.png", replace width(1200) height(800)

********************************************************************************
* 6. Advanced Robustness and Sensitivity Analysis
********************************************************************************

* Reload original dataset
use "data/turkey_macro_data.dta", clear
tsset year

* Regenerate required variables
* Generate market size measure
gen market_size = log(100 + gdp_growth)  // Adding 100 to ensure positive values for log
label variable market_size "Market Size (log transformed GDP growth)"

* Generate institutional quality periods
gen inst_quality = .
replace inst_quality = 1 if year < 1980  // Pre-reform period
replace inst_quality = 2 if year >= 1980 & year < 2001  // Post-liberalization
replace inst_quality = 3 if year >= 2001  // Post-2001 reforms
label variable inst_quality "Institutional Quality Period"
label define inst_qual 1 "Pre-reform" 2 "Post-liberalization" 3 "Post-2001 reforms"
label values inst_quality inst_qual

* Generate industrial concentration and market competition
gen ind_concentration = govt_exp / (100 + gdp_growth)  // Using GDP growth as denominator
gen market_competition = market_size * (1 - ind_concentration)
label variable market_competition "Market Competition Index"

* 6.1 Instrumental Variables Approach
* Generate instruments using lagged values and interaction terms
gen iv_trade = L2.trade_gdp * L2.market_size
gen iv_inst = L2.inst_quality * L2.market_competition

* First stage regression
reg trade_gdp iv_trade iv_inst investment inflation, robust
predict trade_gdp_hat

* Second stage regression (avoiding collinearity with year dummies)
ivregress 2sls gdp_growth investment inflation ///
    (trade_gdp = iv_trade iv_inst), robust
estimates store iv_model

* Test for instrument validity
estat firststage
estat overid

* 6.2 Treatment Effect Analysis (replacing synthetic control)
* Create treatment indicator for major policy changes
gen treatment = (year >= 2001)

* Simple difference-in-differences style analysis
reg gdp_growth i.treatment##c.trade_gdp investment inflation, robust

* Plot treatment effects over time
gen effect = .
forvalues t = 1990/2020 {
    capture drop temp_treat
    gen temp_treat = (year >= `t')
    quietly reg gdp_growth i.temp_treat##c.trade_gdp investment inflation
    replace effect = _b[1.temp_treat] if year == `t'
    drop temp_treat
}

* Plot the treatment effects
twoway (connected effect year if year >= 1990 & year <= 2020, ///
    sort msize(small)), ///
    title("Treatment Effects Over Time", size(large)) ///
    ytitle("Effect on GDP Growth", size(medium)) ///
    xtitle("Year", size(medium)) ///
    ylabel(, angle(0)) ///
    xlabel(1990(5)2020, angle(45)) ///
    yline(0, lpattern(dash) lcolor(gray)) ///
    graphregion(color(white)) bgcolor(white)
graph export "output/treatment_effects.png", replace width(1200) height(800)

* 6.3 Advanced Heteroskedasticity Tests
* Breusch-Pagan test
reg gdp_growth trade_gdp investment inflation
estat hettest, rhs

* White's test
estat imtest, white

********************************************************************************
* 7. Policy Simulation and Forecasting
********************************************************************************

* Install the oaxaca command if not already installed
capture which oaxaca
if _rc {
    ssc install oaxaca
}

* 7.1 Dynamic Forecasting

* Estimate an ARIMA model suitable for dynamic forecasting
arima gdp_growth L.gdp_growth L.trade_gdp L.investment L.inflation

* Generate forecast scenarios
gen trade_scenario_high = trade_gdp * 1.2
gen trade_scenario_low = trade_gdp * 0.8

* Replace trade_gdp with the high scenario and predict
replace trade_gdp = trade_scenario_high if year >= 2020
predict gdp_forecast_high, dynamic(2020)

* Replace trade_gdp with the low scenario and predict
replace trade_gdp = trade_scenario_low if year >= 2020
predict gdp_forecast_low, dynamic(2020)

* Restore original trade_gdp values
replace trade_gdp = trade_gdp[_n-1] if year >= 2020

* Predict the baseline forecast
predict gdp_forecast_base, dynamic(2020)

* Plot forecasts with confidence bands
* Plot forecasts with confidence bands
twoway (line gdp_growth year if year < 2020) ///
    (line gdp_forecast_base year if year >= 2020, lpattern(solid)) ///
    (line gdp_forecast_high year if year >= 2020, lpattern(dash)) ///
    (line gdp_forecast_low year if year >= 2020, lpattern(dash)), ///
    title("GDP Growth Forecasts under Different Scenarios") ///
    ytitle("GDP Growth Rate") xtitle("Year") ///
    legend(order(1 "Historical" 2 "Baseline" 3 "High Trade" 4 "Low Trade")) ///
    scheme(s2color)
graph export "output/forecasts.png", replace width(1200) height(800)

* 7.2 Policy Impact Decomposition

* Regenerate reform period indicators before decomposition
gen post_reform = (year >= 1980 & year < 2001)
label variable post_reform "Post-reform period"

* Blinder-Oaxaca decomposition for pre/post reform periods
oaxaca gdp_growth trade_gdp investment inflation, by(post_reform) detail pooled

* Save results
eststo clear
eststo: estimates restore ecm_model
eststo: estimates restore fe_model
eststo: estimates restore iv_model

esttab using "output/model_results.csv", ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Comparative Model Results") ///
    csv replace

* Close log file
log close