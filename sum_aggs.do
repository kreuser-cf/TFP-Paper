set linesize 255
cd "${paperfolder}\OutputData\sum_stats\"
use "${paperfolder}\\PerpetualInventoryCapitalStock\AddedData\deflator_final.dta", clear 
keep if sic5==3 
gen vadefl = defl_grossvaladd/100 
keep if quarter==1 
save defl_dat.dta, replace 
local sadr = "${paperfolder}\Tables\Sample\"

use "${paperfolder}\\\addataadr\QFS_F.dta", clear 
keep if industry=="manuf" 
keep if size=="total"
gen valadd = y_turn - x_purch - inv_open + inv_clos
foreach var in y_turn valadd { 
	gen tot_`var' = `var'*4 if yearq==200 
	xtset id yearq 
	replace tot_`var'= `var' + l.`var' + l2.`var' + l3.`var' if tot_`var'==. 
	replace tot_`var' = tot_`var'*1000000
}
keep if quarter=="q1"
destring year, gen(taxyear)
save QFS_manuf.dta, replace  



clear 
cd "${main_out_folder}\\output_p3_isic4_str_d19\pi_iv_fixed_pd_10\kerr_w_b\va_A\real_int_lag\"
use "${paperfolder}\\OutputData\sum_stats\full_sumstats_pi_iv_fixed_pd_10_kerr_w_b_real_int_isic4_str_taxyear.dta", clear
keep taxyear  isic4_str sum_o* sum_y* sum_l* sum_k* 
keep if isic4_str!=""
drop isic4_str
keep if taxyear>2009 
ds sum_* 
collapse (sum) `r(varlist)' , by(taxyear)
local year = 2010 
gen qes = . 
foreach val in 1199000  1172592	1167738	1165025	1168465	1161042	1179176	1191364	1203950 { 
	replace qes = `val' if taxyear==`year'
	local ++year
}
gen year = taxyear



merge 1:1 year using "${paperfolder}\\PerpetualInventoryCapitalStock\AddedData\AFS_3.dta", keep(master matched)
preserve 
use "${paperfolder}\\PerpetualInventoryCapitalStock\FigTabsData\afs_pi_stats.dta", clear 
keep if sic5==3 
save afs_pi.dta, replace 
restore 
ds sum*
foreach var in `r(varlist)' { 
	foreach v in y o k l m { 
		if regexm("`var'","exp_`v'")==1 { 
			local v = subinstr("`var'","exp_`v'","`v'",.)		
			rename `var' `v'
		}
	}
}
cd "${paperfolder}\\OutputData\sum_stats\"

merge 1:1 taxyear using afs_pi.dta, keepusing(afs_k_ppeint_pi) keep(master matched) gen(pi)
merge 1:1 taxyear using defl_dat.dta, keepusing(vadefl) keep(master matched) gen(defl)
merge 1:1 taxyear using QFS_manuf, keepusing(tot_y_turn tot_valadd)  gen(vala) keep(master matched)


gen afs_o = (tot_y_turn/vadefl)/1000000
gen afs_y =((tot_valadd)/vadefl)/1000000
gen afs_k = afs_k_ppeint_pi/1000000
gen afs_l = qes/1

foreach var in y l o k { 
	local mult = 1000000
	if "`var'"=="l" { 
		local mult = 1
	}
	gen dat_`var'_1_1 = sum_`var'/`mult'
	gen dat_`var'_1_2 =  100*dat_`var'_1_1/afs_`var'
	forv i = 2/5 {
		gen dat_`var'_`i'_1 = sum_`var'_`i'/`mult'
		gen dat_`var'_`i'_2 = 100*dat_`var'_`i'_1/dat_`var'_1_1
		gen dat_`var'_`i'_3 = 100*dat_`var'_`i'_1/dat_`var'_`=`i'-1'_1
		gen dat_`var'_`i'_4 = 100*dat_`var'_`i'_1/afs_`var'		
	}
	gen dat_`var'_6_1 = sum_`var'_5_lag/`mult'
	gen dat_`var'_6_2 = 100*dat_`var'_6_1/dat_`var'_1_1
	gen dat_`var'_6_3 = 100*dat_`var'_6_1/dat_`var'_5_1	
	gen dat_`var'_6_4 = 100*dat_`var'_6_1/afs_`var'	
	gen dat_`var'_8_1 = afs_`var'
	}

save sum_stats_exp.dta, replace 

clear 
cd "${main_out_folder}\\output_p3_isic4_str_d19\pi_iv_fixed_pd_10\kerr_w_b\va_A\real_int_lag\"
forv i = 10/32 { 
	cap noisily append using exp_sumstats_pi_iv_fixed_pd_10_kerr_w_b__`i'_blim_taxyear.dta 
}
keep taxyear  sum_exp*
keep if taxyear>2009 
ds sum_* 
collapse (sum) `r(varlist)' , by(taxyear)
ds sum*
foreach var in `r(varlist)' { 
	foreach v in y o k l m { 
		if regexm("`var'","exp_`v'")==1 { 
			local v = subinstr("`var'","exp_`v'","`v'",.)		
			rename `var' `v'
		}
	}
}
foreach var in y l o k { 
	local mult = 1000000
	if "`var'"=="l" { 
		local mult = 1
	}
	gen dat_`var'_7_1 = sum_`var'_5_lag/`mult'
}

keep taxyear dat_* 
cd "${paperfolder}\\OutputData\sum_stats\"
merge 1:1 taxyear using sum_stats_exp.dta, gen(mn)
foreach var in y l o k { 
	gen dat_`var'_7_2 = 100*dat_`var'_7_1/dat_`var'_1_1
	gen dat_`var'_7_3 = 100*dat_`var'_7_1/dat_`var'_6_1	
	gen dat_`var'_7_4 = 100*dat_`var'_7_1/afs_`var'	
}

local o = "Sales"
local y = "Value Added"
local l = "Labour"
local k = "Capital Stock"
local d_o =  0
local d_y  = 3 
local d_k = 4
local d_l = 5 


foreach var in y o k l { 
	preserve 
	keep taxyear dat_`var'* 
	local list = ""
	forv i = 1/8 { 
		local list = "`list' dat_`var'_`i'_"
	}
	reshape long `list' , i(taxyear) j(subrow)
	reshape long dat_`var'_ , i(taxyear subrow) j(row) str
	reshape wide dat_ , i(row subrow) j(taxyear)

	qui replace row = subinstr(row,"_","",.)
	destring row, replace 
	sort  row subrow
	drop if subrow>2 & row==1 
	drop if subrow==2 & row==2
	drop if subrow>1 & row==8
	gen name = "With Sales" if row==1 & subrow==1 
	qui replace name = "and Cost of Sales" if row==2 & subrow==1 
	qui replace name = "and Positive V.A" if row==3 & subrow==1
	qui replace name = "and Capital Stock" if row==4 & subrow==1
	qui replace name = "and Employment" if row==5 & subrow==1
	qui replace name = "with lags" if row==6 & subrow==1
	drop if row==`d_`var'' 
	replace name = "Sample Restrictions" if row==7 & subrow==1 
	replace name = "AFS ``var''" if row==8 
	if "`var'"=="l" { 
		replace name = "QES Employment" if row==8
	}
	if "`var'"=="y" | "`var'"=="o" { 
		replace name = "QFS ``var''" if row==8
	}
	ds dat* 
	foreach vv in `r(varlist)' { 
		qui replace `vv' = `vv' if subrow>1
		qui tostring `vv', replace force format(%10.4gc)
		qui replace `vv' = "("+`vv'+"\%)" if subrow==2 & row>2  		
		qui replace `vv' = "["+`vv'+"\%]" if subrow==3 
		qui replace `vv' = `vv'+"\%" if subrow==4 
		qui replace `vv' = `vv'+"\%" if subrow==2 & row==1 
	}
	local counter = 1 
	local rc = 1 
	qui log using "`sadr'\\agg_sum_stats_`var'.txt", replace  t 
	di "\begin{tabular}{lcccccccc}"
	di " & 2010 & 2011 & 2012 & 2013 & 2014 & 2015 & 2016 & 2017 \\"
	di "\hline"
	qui log close 
	count 
	forv j = 1/`r(N)' { 
		local line = name in `j'
		forv yr = 2010/2017 { 
			local a = dat_`var'_`yr' in `j'
			local line  = "`line' & `a'"
		}
		local line = "`line' \\"
		qui log using "`sadr'\\agg_sum_stats_`var'.txt", append t 
		di "`line'"
		qui log close
	}
	qui log using "`sadr'\\agg_sum_stats_`var'.txt", append t
	di "\hline"
	di "\end{tabular}"
	qui log close 
	restore 
}          