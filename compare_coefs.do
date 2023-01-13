clear 
forv i = 10/32 { 
	cap noisily append  using "${main_out_folder}\\output_p3_isic4_str_${vrs}\pi_iv_fixed_pd_10\kerr_w_b\va_A\real_int_lag\manuf_noiv_basic_3pol_blim_va_a_pi_iv_fixed_pd_10_kerr_w_b_real_gcos_a_real_int_lag_`i'.dta"
}
preserve 
keep if est=="GMM" 
drop if ind=="12"
gen bl_low = bl-1.96*bl_se 
gen bl_high = bl+1.96*bk_se 
gen bk_low = bk-1.96*bk_se
gen bk_high = bk+1.96*bk_se 
keep ind bl* bk*
keep ind bl_low bl bl_high bk_low bk bk_high
order ind bl_low bl bl_high bk_low bk bk_high
ds b* 
foreach var in `r(varlist)' { 
	rename `var' new_`var'
}
destring ind , replace 
merge 1:1 ind using "${paperfolder}\FigData\gmm_coefs.dta"

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
		local ind_22 = "22 Rubber and Plastics"
		local ind_20 = "20 Chemicals and Pharma"
		local ind_21 = "21 Pharma"
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
					replace ind = -ind
						forv i = 10/32 { 
						label def ind -`i' "`ind_`i''", modify
					}				
					label val ind ind 
label var ind "Industry"
twoway (pccapsym ind new_bl_low ind new_bl_high, msymbol(pipe)) ///
		(pccapsym ind bl_low ind bl_high, msymbol(pipe)) ///
		, ylabel(-32(1)-10, angle(horizontal) valuelabel) ymtick(-32(1)-10, valuelabel) scheme(friendly) legend(label (1 "{&beta}{sub:l} Wooldridge") label(2 "{&beta}{sub:l} Wooldridge (KN, 2018)")) 
		gr export "${paperfolder}\figs\gmm_bl.pdf", replace 
twoway (pccapsym ind new_bk_low ind new_bk_high, msymbol(pipe)) ///
		(pccapsym ind bk_low ind bk_high, msymbol(pipe)) ///
		, ylabel(-32(1)-10, angle(horizontal) valuelabel) ymtick(-32(1)-10, valuelabel) scheme(friendly) legend(label (1 "{&beta}{sub:k} Wooldridge") label(2 "{&beta}{sub:k} Wooldridge (KN, 2018)")) 
		gr export "${paperfolder}\figs\gmm_bk.pdf", replace 

		