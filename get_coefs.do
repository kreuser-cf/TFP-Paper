/* 
This do-file gwet
*/
/* make tables main folder */
cap mkdir "${paperfolder}\\Tables\"
cd "${paperfolder}\\Tables\"
/* Make data storage folder */
local tabdata = "${paperfolder}\Tables\data\"
cap mkdir "${paperfolder}\Tables\data\" 
/* set coefs foder */ 
local coef_folder = "${paperfolder}\\Tables\\coefs"
local version = "d19"

cd "`tabdata'"
local intvar = "real_int_lag"
local emp = "kerr_w_b"
local va = "va_A"
local capvar = "pi_iv_fixed_pd_10"
local ivs = "noiv"
local indvar = "isic4_str_`version'"
local isic4_str_`version' = "each ISIC4 industry at the 2-digit level."
local alim = "The sample removes firms that ever had a ratio of output to labour, output to capital, or capital to labour lower than the 1st percentile or greater than the 99th percentile for the entire industry over all periods"
local blim = "The sample removes firms that ever had a ratio of output to labour, output to capital, or capital to labour lower than the 1st percentile or greater than the 99th percentile for the entire industry for each individual year"

local poly = "3"
local prefix = "output"
local outputfolder = "${main_out_folder}\\`prefix'_p`poly'_`indvar'"
cap mkdir "Tables\coefs\"
cap mkdir "`coef_folder'\\`indvar'"
cap mkdir "`coef_folder'\\`indvar'\\p`poly'"
local adr = "`coef_folder'\\`indvar'\\p`poly'" 
local tabfolder = "Tables/coefs/`indvar'/p`poly'/"
set linesize 255
/* 1. Loop Over Samples */
foreach lim in  blim { 
	cap mkdir "`adr'"
	local bfolder = "`adr'\\`capvar'\\`lim'\\"
	local sfolder ="`adr'\\`capvar'\\`lim'\\subtabs\\"
	cap mkdir "`adr'"
	cap mkdir "`adr'\\`capvar'"
	cap mkdir "`bfolder'"
	cap mkdir "`sfolder'"
	local files: dir "`bfolder'" files "*.txt"
	foreach file in `files' {
		erase `bfolder'\\`file'
	}
	local files: dir "`sfolder'" files "*.txt"
	foreach file in `files' {
		erase `sfolder'\\`file'
	}
	
	local dir = "`outputfolder'\\`capvar'\\`emp'\\`va'\\`intvar'"
	cd "`dir'"
	local iv = 2 
	local noiv = 1 
	/* 1.1 Start loop over IV*/
	foreach v in   noiv {
		/* 1.1.1. Loop over Industries */
		forv indus = 10/32 { 
			cap noisily use manuf_`v'_basic_3pol_`lim'_va_a_`capvar'_`emp'_real_gcos_a_`intvar'_`indus'.dta , clear 
			if _rc==0 {
				gen tag = 0
				gen potuse = 0
				gen tag_me = 0 	
				if "`v'"=="noiv" {
				/* The original code had an error where the prodest_full rts test reported the ACF's result*/

					foreach est in ols_samp GMM prodest_acf { 
						replace potuse = 1 if est=="`est'"
						replace tag_me = 1 if est=="`est'"
					}
					foreach est in basic_bs  basic_pe_bs altinit_bs grid_bs   { 
						replace tag = 1 if est=="`est'" & bl>0.2 & bl<1 & bk>0 & bk<1 & gb2>0 & gb2<1
					} 
	
					replace tag_me = 1 if est=="basica_bs"

					keep if tag_me==1 
					ds * , has(type numeric)
					foreach var in `r(varlist)' { 
						replace `var' = . if `var'==-99
					}
					replace gb2 = . if est=="GMM" 
					replace gb2_se = . if est=="GMM" 
					replace gb1 = . if est=="GMM" 
					replace gb1_se = . if est=="GMM" 		
					save "`tabdata'\\c_manuf_`v'_basic_3pol_`lim'_va_a_`capvar'_`emp'_real_gcos_a_`intvar'_`indus'.dta", replace 					
				}			

			}
		}
	}
	foreach v in    noiv {
		clear 
		/* 1.2. Create Data For tables */
		/* 1.2.1. Append data*/
		cd "`tabdata'"
		forv indus = 10/32 { 	
			capture noisily append using "`tabdata'\\c_manuf_`v'_basic_3pol_`lim'_va_a_`capvar'_`emp'_real_gcos_a_`intvar'_`indus'.dta"
		}
		/* 1.2.2. Create p-values, note that bootstrapped standard errors are under the assumption of a normal dist */
		foreach var in bk bl  gb2 {
			gen `var'_pval = 2*(1-normal(abs(`var'/(`var'_se)))) if regexm(est,"prodest")==1 
			replace `var'_pval = 2*(1-normal(abs(`var'/(`var'_se+.0000001)))) if regexm(est,"bs")==1 
			replace `var'_pval = 2*ttail((obs-3),abs(`var'/(`var'_se))) if regexm(est,"ols")==1
			replace `var'_pval = 2*ttail((obs-3),abs(`var'/(`var'_se))) if regexm(est,"FE")==1
			replace `var'_pval = 2*ttail((obs-3),abs(`var'/(`var'_se))) if regexm(est,"GMM")==1
			gen `var'_star = "*" if `var'_pval<.1 
			replace `var'_star = "**" if `var'_pval<.05
			replace `var'_star = "***" if `var'_pval<.001
		}
		/* round and format, butnot se*/
		foreach var in bk bl  gb2 {
			replace `var' = round(`var',.001)
			tostring `var' `var'_se, replace force format(%5.4g)
			replace `var' = substr(`var',1,4)+`var'_star
			replace `var'_se = "("+substr(`var'_se,1,4)+")" if `var'_se!="."
		}
		drop if obs==. 

		
		clear 
		cd "`tabdata'"
		forv indus = 10/32 { 	
			capture noisily append using "`tabdata'\\c_manuf_`v'_basic_3pol_`lim'_va_a_`capvar'_`emp'_real_gcos_a_`intvar'_`indus'.dta"
		}
		foreach var in bk bl  gb2 {
			gen `var'_pval = 2*(1-normal(abs(`var'/(`var'_se)))) if regexm(est,"prodest")==1 
			replace `var'_pval = 2*(1-normal(abs(`var'/(`var'_se+.0000001)))) if regexm(est,"bs")==1 
			replace `var'_pval = 2*ttail((obs-3),abs(`var'/(`var'_se))) if regexm(est,"ols")==1
			replace `var'_pval = 2*ttail((obs-3),abs(`var'/(`var'_se))) if regexm(est,"FE")==1
			replace `var'_pval = 2*ttail((obs-3),abs(`var'/(`var'_se))) if regexm(est,"GMM")==1
			gen `var'_star = "*" if `var'_pval<.1 
			replace `var'_star = "**" if `var'_pval<.05
			replace `var'_star = "***" if `var'_pval<.001
		}
		foreach var in bk bl  gb2 {
			replace `var' = round(`var',.001)
			tostring `var' `var'_se, replace force format(%5.4g)
			replace `var' = substr(`var',1,4)+`var'_star
			replace `var'_se = "("+`var'_se+")" if `var'_se!="."
		}
		drop if obs==. 
		rename bl bl_1 
		rename bl_se bl_2 
		rename bk bk_1 
		rename bk_se bk_2 
		rename gb2 rho_1_1 
		rename gb2_se rho_1_2 
		rename crit crit_1 
		rename obs crit_2
		drop *_pval *_star
		replace crit_1 = round(crit_1,.001) if  est=="ols" | est=="ols_samp"  | est=="ols_samp_IV" | est=="GMM" | est=="GMM_IV"   | est=="FE" 

		tostring crit_1 , replace format(%6.1gc) force	
		cap confirm variable rtsp 
		if _rc==0 {
			cap drop crits_star 
			gen crits_star = "*" if rtsp>=.05 & rtsp!=. 
			replace crits_star = "***" if rtsp>=.1 & rtsp!=. 
			replace crit_1 = crit_1 + crits_star
		}
		tostring crit_2 , replace format(%9.1gc) force 	


		reshape long crit_  bl_ bk_  rho_1_  , i(est ind sales capital emp costvar intvar est_type  ) j(rn)
		tab ind 
		cap drop order 
		gen order = .
		local order = 1 
		foreach est in ols_samp GMM prodest_acf prodest_full basica_bs  basicaols_bs basic_pe_bs  basicols_pe_bs { 
			replace order = `order' if est=="`est'"
			local order=`order'+1
			
		}
		local cdc = 8
		local lss = 7


		sort ind order rn
			
		rename bl beta_l
		rename bk beta_k 
		rename rho_1_ rho_1
		sort ind order est est_type rn
		foreach var in beta_l beta_k  rho_1 { 
			replace `var' = "" if `var'=="."
		}
		gen name = "" 
		replace name = "OLS\$^\star\$" if est=="ols_samp" & rn==1
		replace name = "Wooldridge (KN)\$^{\star}\$" if est=="GMM" & rn==1
		replace name = "PRODEST ACF\$^{\star\star}\$" if est=="prodest_acf" & rn==1
		replace name = "PRODEST Full\$^{\star\star}\$" if est=="prodest_full" & rn==1
		*replace name = "PRODEST Wooldridge\$^{\dagger\dagger\dagger}\$" if n_1=="prodestwrdg" & rn==1
		replace name = "ACF\$(\rho)\$\$^{\dagger}\$" if est=="basica_bs" & rn==1
		replace name = "ACF\$(\rho)\$\$^{\dagger}\$" if est=="basicaols_bs" & rn==1

		replace name = "ACF OLS Init.\$^{\dagger}\$" if est=="basic_bs" & rn==1
		replace name = "ACF OLS Init. SS\$^{\dagger}\$" if est=="basic_pe_bs" & rn==1
		replace name = "ACF TRUE OLS Init. SS\$^{\dagger}\$" if est=="basicols_pe_bs" & rn==1
		replace name = "ACF .5 Init.\$^{\dagger}\$" if est=="altinit_bs" & rn==1
		replace name = "ACF Grid Search\$^{\dagger}\$" if est=="grid_bs" & rn==1     		
		replace name = "OLS IV\$^\star\$" if est=="ols_samp_IV" & rn==1
		replace name = "Wooldridge IV (KN)\$^{\star}\$" if est=="GMM_IV" & rn==1
		replace name = "PRODEST ACF IV\$^{\star\star}\$" if est=="prodest_acf_ch" & rn==1
		*replace name = "PRODEST Wooldridge\$^{\dagger\dagger\dagger}\$" if n_1=="prodestwrdg" & rn==1
		replace name = "ACF\$(\rho)\$ OLS Init. IV\$^{\dagger}\$" if est=="basica_IV_bs" & rn==1
		replace name = "ACF OLS Init. IV\$^{\dagger}\$" if est=="basic_IV_bs" & rn==1
		replace name = "ACF OLS Init. SS IV\$^{\dagger}\$" if est=="basic_pe_IV_bs" & rn==1
		replace name = "ACF .5 Init. IV\$^{\dagger}\$" if est=="altinit_IV_bs" & rn==1
		replace name = "ACF Grid Search IV\$^{\dagger}\$" if est=="grid_IV_bs" & rn==1     		

		rename crit_ Stats
		levelsof ind, local(ind2)
		local ind_10 = "10 Food"
		local ind_11 = "11 Beverages"
		local ind_12 = "12 Tobacco" 
		local ind_13 = "13 Textiles"
		local ind_14 = "14 Apparel"
		local ind_15 = "15 Leather and Footwear"
		local ind_16 = "16 Wood" 
		local ind_17 = "17 Paper" 
		local ind_18 = "18 Printing" 
		local ind_19 = "19 Coke and Petroleum" 
		local ind_20 = "20 Chemicals and Pharma"
		local ind_22 = "22 Rubber and Plastics"
		local ind_23 = "23 Non-Metallic Minerals" 
		local ind_24 = "24 Basic Metals" 
		local ind_25 = "25 Fabricated Metals" 
		local ind_26 = "26 Computer and Electronic" 
		local ind_27 = "27 Electrical" 
		local ind_28 = "28 Machinery Equipment N.E.C"
		local ind_29 = "29 Motor Vehicles" 
		local ind_30 = "30 Other Transport Eqipment" 
		local ind_31 = "31 Furniture" 
		local ind_32 = "32 Other Manufacturing"
		local ind_counter = 0 
		local indsinest =0 
		foreach ind of local ind2 { 
			local indsinest = `indsinest'+1  
			preserve 
				keep if ind=="`ind'"
				order name beta_l beta_k rho_1 Stats 
				keep name beta_l beta_k rho_1 Stats
				rename  Stats sstats
				/*tostring(Stats), gen(sstats) format(%9.1gc) force				
				drop Stats*/
					qui count 
					if `r(N)'<`cdc' { 
						set obs `cdc'
						replace name = "N.A\$^{\dagger\dagger}\$" in `=`cdc'-1'
						replace name = "" in `cdc'
					}
				qui log using "`sfolder'\\`v'_withadd_`ind'.txt", t replace 
					di "\begin{tabular}{lcccc}"
					di "\hline"
					di "Estimator & \$\beta_l \$  & \$\beta_k\$ & \$\rho_1\$ & Stats \\"
					di "\hline"	

					forv i = 1/`cdc' { 
						foreach var in name beta_l beta_k rho_1 sstats { 
								local v`var' = `var' in `i' 
						}
						di "`vname' & `vbeta_l' & `vbeta_k' & `vrho_1' & `vsstats' \\"  	
					}
					di "\hline"
					di "\end{tabular}"
				qui log close 
				restore
				filefilter  "`sfolder'\\`v'_withadd_`ind'.txt"  "`sfolder'\\a`v'_withadd_`ind'.txt" , from("\n> ") to("") replace	
				filefilter  "`sfolder'\\a`v'_withadd_`ind'.txt"  "`sfolder'\\`v'_withadd_`ind'.txt" , from("\r> ") to("") replace	
				erase "`sfolder'\\a`v'_withadd_`ind'.txt"
		}
		local ind_counter = max(`ind_counter',`indsinest')
		local counter = 0 
		local subtabs = 1 
		local subc = 0 
		local mad = "./`tabfolder'/`capvar'/`lim'/subtabs/"	
		local sad = "`sfolder'"
		levelsof ind, local(ind2) 
		foreach ind of local ind2 {
			if `counter'>`lss' {
				local counter = 0 
				local subtabs = `subtabs'+1		
			}
			if `counter'==0 { 
				qui log using "`sad'\\`v'_table_group_`subtabs'.txt", t replace 		
			}
			else { 
				qui log using "`sad'\\`v'_table_group_`subtabs'.txt", t append
			}
			di "\begin{tiny}"
			di "\subfloat[`ind_`ind'']{\import{`mad'}{`v'_withadd_`ind'.txt}}"
			di "\end{tiny}"
			local subc = `subc'+1
			if `subc'>1 {
				di "" 
				local subc=0
			
			}
			
			qui log close                     
			local counter=`counter'+1  
		}
		local files: dir "`sad'" files "`v'_table_group*.txt"
		local wc = 0 
		foreach file in `files' { 
			local wc = `wc'+1
			filefilter  "`sad'\\`file'"  "`sad'\\a`file'" , from("\n> ") to("") replace	
			filefilter  "`sad'\\a`file'"  "`sad'\\`file'" , from("\r> ") to("") replace	
			erase "`sad'\\a`file'"
		}			
		qui log using "`bfolder'\\`v'_final_withadd.txt", t replace 
		local counter = 1 
		foreach file in `files' { 
			di "\begin{table}[h!]\caption{\label{tab:withadd_`counter'} Estimates Part `counter'}" 
			di "\subtablecaptionpos"
			di "\begin{adjustwidth}{\adjusttablestartpos}{}   \begin{center}"
			di "\begin{tiny} \begin{subtable}{1\textwidth}"
			di "\import{`mad'}{`v'_table_group_`counter'.txt}"
			di "\end{subtable} \end{tiny} \end{center} \end{adjustwidth}" 
			di "\tablenotebasic{``indvar''. ``lim''}"
			di "\end{table}"
			di ""
			local counter = `counter'+1
		}			
		qui log close 
		filefilter   "`bfolder'\\`v'_final_withadd.txt"  "`bfolder'\\a`v'_final_withadd.txt" , from("\n> ") to("") replace	
		filefilter   "`bfolder'\\a`v'_final_withadd.txt" "`bfolder'\\`v'_final_withadd.txt" , from("\r> ") to("") replace	
		erase  "`bfolder'\\a`v'_final_withadd.txt"          
	 
	
	}	
}

