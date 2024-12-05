/*******************************************************************************
* Data Preparation for Trade Openness and Economic Growth Analysis - Turkey
* Time Period: 1960-2022 (or latest available)
* Data Sources: World Bank WDI
*******************************************************************************/

clear all
set more off
capture log close

* Set working directory
cd "c:/Users/eren/Desktop/fundshedge"

* Create necessary directories if they don't exist
capture mkdir "output"
capture mkdir "data"

* Start log file
log using "output/data_preparation_log.txt", replace

********************************************************************************
* Install required packages
********************************************************************************
* Install wbopendata from SSC
capture ssc install wbopendata, replace
capture ssc install estout, replace

********************************************************************************
* Download World Development Indicators Data
********************************************************************************

* Create temporary files for each indicator
tempfile gdp trade exports imports industry gdppc inflation govt_exp education merged

* Load GDP growth data for Turkey
clear
wbopendata, language(en) country(TUR) year(1960:2022) indicator(NY.GDP.MKTP.KD.ZG) clear
keep if countryname == "Turkey"
keep yr* countryname
reshape long yr, i(countryname) j(year)
rename yr gdp_growth
save `gdp'

* Download trade
clear
wbopendata, language(en) country(TUR) year(1960:2022) indicator(NE.TRD.GNFS.ZS) clear
keep if countryname == "Turkey"
keep yr* countryname
reshape long yr, i(countryname) j(year)
rename yr trade_gdp
save `trade'

* Download exports
clear
wbopendata, language(en) country(TUR) year(1960:2022) indicator(NE.EXP.GNFS.ZS) clear
keep if countryname == "Turkey"
keep yr* countryname
reshape long yr, i(countryname) j(year)
rename yr exports_gdp
save `exports'

* Download imports
clear
wbopendata, language(en) country(TUR) year(1960:2022) indicator(NE.IMP.GNFS.ZS) clear
keep if countryname == "Turkey"
keep yr* countryname
reshape long yr, i(countryname) j(year)
rename yr imports_gdp
save `imports'

* Download industry value added
clear
wbopendata, language(en) country(TUR) year(1960:2022) indicator(NV.IND.TOTL.ZS) clear
keep if countryname == "Turkey"
keep yr* countryname
reshape long yr, i(countryname) j(year)
rename yr investment
save `industry'

* Download GDP per capita
clear
wbopendata, language(en) country(TUR) year(1960:2022) indicator(NY.GDP.PCAP.KD) clear
keep if countryname == "Turkey"
keep yr* countryname
reshape long yr, i(countryname) j(year)
rename yr gdp_pc
save `gdppc'

* Download inflation
clear
wbopendata, language(en) country(TUR) year(1960:2022) indicator(FP.CPI.TOTL.ZG) clear
keep if countryname == "Turkey"
keep yr* countryname
reshape long yr, i(countryname) j(year)
rename yr inflation
save `inflation'

* Download government expenditure
clear
wbopendata, language(en) country(TUR) year(1960:2022) indicator(GC.XPN.TOTL.GD.ZS) clear
keep if countryname == "Turkey"
keep yr* countryname
reshape long yr, i(countryname) j(year)
rename yr govt_exp
save `govt_exp'

* Download tertiary education
clear
wbopendata, language(en) country(TUR) year(1960:2022) indicator(SE.ENR.TERT.FM.ZS) clear
keep if countryname == "Turkey"
keep yr* countryname
reshape long yr, i(countryname) j(year)
rename yr tertiary_educ
save `education'

* Merge all datasets
use `gdp', clear
merge 1:1 year using `trade', nogen
merge 1:1 year using `exports', nogen
merge 1:1 year using `imports', nogen
merge 1:1 year using `industry', nogen
merge 1:1 year using `gdppc', nogen
merge 1:1 year using `inflation', nogen
merge 1:1 year using `govt_exp', nogen
merge 1:1 year using `education', nogen

* Label variables
label variable gdp_growth "GDP Growth (annual %)"
label variable trade_gdp "Trade (% of GDP)"
label variable exports_gdp "Exports (% of GDP)"
label variable imports_gdp "Imports (% of GDP)"
label variable investment "Industry Value Added (% of GDP)"
label variable gdp_pc "GDP per capita (constant 2015 US$)"
label variable inflation "Inflation, consumer prices (annual %)"
label variable govt_exp "Government Expenditure (% of GDP)"
label variable tertiary_educ "School enrollment, tertiary (% gross)"

* Generate interaction terms and squared terms
generate trade_inv_int = trade_gdp * investment
generate trade_educ_int = trade_gdp * tertiary_educ
generate trade_gdp_sq = trade_gdp^2

* Label generated variables
label variable trade_inv_int "Trade-Investment Interaction"
label variable trade_educ_int "Trade-Education Interaction"
label variable trade_gdp_sq "Trade Squared"

* Save final dataset
save "data/turkey_macro_data.dta", replace

* Export to Excel
export excel using "data/turkey_macro_data.xlsx", firstrow(variables) replace

* Close log file
log close

exit
