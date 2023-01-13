cap program drop tfp_aggregates
    program define tfp_aggregates 
    syntax , paperfolder(string)

    cap log close 
    clear 
    forv i = 10/32 {
    cap noisily append using "`paperfolder'\\Tables\data\c_manuf_noiv_basic_3pol_blim_va_a_pi_iv_fixed_pd_10_kerr_w_b_real_gcos_a_real_int_lag_`i'.dta"
    }
    drop sales capital emp costvar intvar est_type tag potuse tag_me
    rename gb1  rho0
    rename gb2  rho1
    rename gb3 rho2 
    rename gb4  rho3 
    rename gb1_se  rho0_se
    rename gb2_se  rho1_se
    rename gb3_se rho2_se 
    rename gb4_se  rho3_se 
    ds est ind , not 
    local vlist = ""
    foreach var in `r(varlist)'  { 
        rename `var' `var'_ 
        local vlist = "`vlist' `var'_"
    }
    replace est = "OLS" if est=="ols_samp"
    replace est = "WLD" if est=="GMM"
    replace est = "ACFp" if est=="basica_bs"
    replace est = "PRODEST" if est=="prodest_acf"
    replace rho2_ =. if est=="WLD"
    replace rho2_se_ = . if est=="WLD"

    reshape wide `vlist' , i(ind) j(est) str 
    local crit = "Critical Val"
    local obs = "Observations"
    local rtsp = "P-Val for Retruns to Scale Test"
    local bl = "beta_l"
    local bk = "beta_k"
    local bl_se = "SE beta_l"
    local bk_se = "SE beta_k"
    forv i = 1/4 { 
        local rho`i' = "rho_`i'"
        local rho`i'_se = "SE rho_`i'"
    }
    local ACFp = "ACF(p)"
    local WLD = "Wooldridge (KN)"
    local PRODEST = "PRODEST"
    local OLS = "OLS"
    foreach var in crit obs rtsp bl bl_se bk bk_se rho1 rho1_se rho2 rho2_se rho3 rho3_se rho0 rho0_se { 
        foreach est in ACFp WLD PRODEST OLS { 
            label var `var'_`est' "``var'' for ``est''"
        }
    }
    rename ind isic4_str
    save "`paperfolder'\\Productivity_Coefs.dta",  replace 

    clear 
    forv i = 10/32 {
    cap noisily append using "`paperfolder'\\OutputData\2021-06-25\output_p3_isic4_str_d19\real_kppe\kerr_w_b\va_A\real_int_lag\exp_sumstats_real_kppe_kerr_w_b__`i'_taxyear.dta"
    capture gen isic4_str = "`i'"
    replace isic4_str = "`i'" if isic4_str==""
    }
    keep isic4_str taxyear sum_exp_y_5_lag sum_exp_o_5_lag sum_exp_m_5_lag sum_exp_l_5_lag sum_exp_k_5_lag

    save "`paperfolder'\\OutputData\sample_aggs.dta", replace 

    use "`paperfolder'\\OutputData\prodindex_withlims_noiv_blim_isic4_str_pi_iv_fixed_pd_10_kerr_w_b_va_A_real_int_lag.dta", clear 
    local sd ="`paperfolder'\\Tables\Index\"
    cd "`sd'"

    mata: est_mat = J(14,3,.)

    local counter = 1
    foreach estimator in op_basica_bs   {
        local op_basica_bs = "ACFp"
        local oy_GMM = "WLD"
        local tfp_pda = "PRODEST"
        foreach sh in sales  {
            preserve 
                local listy = "isic4_str taxyear"
                local rslist = ""
				* Outliers still appeared to dominate the sample, so we tried to balance as much data as we could with restriction
				
                foreach pct in lim tl95 tl99 tl999 t95 t99 t999 95 99 999 {
                    ds `estimator'_pv_`sh'_`pct'
                    foreach var in `r(varlist)' { 
                            local a = subinstr("`var'","pv_`sh'","pv_a_`sh'",.)
                            rename `a' `var'_1 
                            local listy = "`listy' `var'_1 "
                            local a = subinstr("`var'","pv_`sh'","pv_d_`sh'",.)
                            rename `a' `var'_2 
                            local listy = "`listy' `var'_2 "
                        if regexm("`var'","pv_a_`sh'")==0 & regexm("`var'","pv_d_`sh'")==0 {
                            rename `var' `var'_0
                            local listy = "`listy' `var'_0 "
                            local rslist = "`rslist' `var'_"
                        }
                    }
                }
                
                    keep `listy'  
                    forv j = 0/2 { 
                        gen tfp_`estimator'_`j' =  `estimator'_pv_`sh'_t99_`j'
                    }
                        * Beverages has jumps to around 300 points without restrictions
                    forv i = 0/2 { 
                        replace tfp_`estimator'_`i' = `estimator'_pv_`sh'_95_`i' if isic4_str=="11"
                        * Apparell drops by 14 points and immediately recovers, all of this is in d, indicating it is likely a sample thing
                        replace tfp_`estimator'_`i' = `estimator'_pv_`sh'_95_`i' if isic4_str=="14"
                        * Wood Drops to 77 from a high of 125 near the end of the  sample the standard 95 numbers seem inplasabile compared to previous findings
                        replace tfp_`estimator'_`i' = `estimator'_pv_`sh'_t95_`i' if isic4_str=="16"
                        * printing drops by around 20 points in a year, again likely a sample thing
                        replace tfp_`estimator'_`i' = `estimator'_pv_`sh'_t95_`i' if isic4_str=="18"
                        * Petroleum drops bby 40 points in a single year, looks like a pretty persistent sample thing
                        replace tfp_`estimator'_`i' = `estimator'_pv_`sh'_t95_`i' if isic4_str=="19"
                        * Other transport jumps pretty substantially (can be above 2000) if not taken care of
                        replace tfp_`estimator'_`i' = `estimator'_pv_`sh'_t95_`i' if isic4_str=="30"
                    }
                    keep isic4_str taxyear tfp_`estimator'_0 tfp_`estimator'_1 tfp_`estimator'_2  


                    
                    merge m:1 isic4_str taxyear using "`paperfolder'\\OutputData\sample_aggs.dta", gen(aggs) 
                    gen caplab = sum_exp_k_5_lag/sum_exp_l_5_lag
                    gen outlab = sum_exp_y_5_lag/sum_exp_l_5_lag
                    gen outcap = sum_exp_y_5_lag/sum_exp_k_5_lag
                    local indlist = ""
                    foreach var in caplab outlab outcap  { 
                        gen `var'2010 = `var' if taxyear==2010 
                        bys isic4: egen `var'_2010 = mode(`var'2010)
                        gen `var'_index_ =  `var'/`var'_2010
                        local indlst = "`indlst' `var'_index"

                    }
                    keep tfp_`estimator'_0 tfp_`estimator'_1 tfp_`estimator'_2   `indlist' isic4_str taxyear  caplab_index_ outlab_index_ outcap_index_ 
                    drop if taxyear==2009
                    merge m:1 isic4_str using "`paperfolder'\\Productivity_Coefs.dta", gen(coefs)
                    egen idused = group(isic4_str)
                    xtset idused taxyear
                    local counter = 1 
                    foreach esti in op_basica_bs tfp_pda oy_GMM  { 
                        reg tfp_`estimator'_2 bk_``esti'' bl_``esti'' caplab_index_ outlab_index_ outcap_index_   if taxyear>2010 & isic4_str!="12"
            
                    local obs = `e(N)'
                    local r2 = `e(r2_a)'              
                    local bk_coef = _b[bk_``esti'']
                    local bk_se = _se[bk_``esti'']
                    local bl_coef = _b[bl_``esti'']
                    local bl_se = _se[bl_``esti'']
                    local cons_coef = _b[_cons]
                    local cons_se = _se[_cons]
                    foreach sv in caplab_index_ outlab_index_ outcap_index_ { 
                        local `sv'_coef = _b[`sv']
                        local `sv'_se = _se[`sv']
                        }
                    local vc = 1 
                    foreach svs in bk bl caplab_index_ outlab_index_ outcap_index_ cons { 
                        foreach svs2 in coef se { 
                            mata: est_mat[`vc',`counter']  = ``svs'_`svs2''
                            local vc= `vc'+1

                        }
                    }


                    mata: est_mat[`vc',`counter'] = `r2'
                    mata: est_mat[`=`vc'+1',`counter'] = `obs'    
                    local counter = `counter'+1
                }

                    reshape long tfp_`estimator'_  , i(isic4_str taxyear caplab_index_ outlab_index_ outcap_index_ ) j(row)
            



                    reshape wide tfp_`estimator'_ caplab_index_ outlab_index_ outcap_index_ , i(isic4_str row) j(taxyear)
                    
        
            


                    gen f = "\$ p_t \$" if row==0 
                    replace f = "\$ \bar{p_t} \$" if row==1 
                    replace f = "\$ d_t \$" if row==2 
                    order isic4_str f 
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
                    local ind_10_1 = "Food"
                    local ind_11_1 = "Beverages"
                    local ind_12_1 = "Tobacco" 
                    local ind_13_1 = "Textiles"
                    local ind_14_1 = "Apparel"
                    local ind_15_1 = "Leather and"
                    local ind_15_2 = "Footwear"
                    local ind_16_1 = "Wood" 
                    local ind_17_1 = "Paper" 
                    local ind_18_1 = "Printing" 
                    local ind_19_1 = "Coke and" 
                    local ind_19_2 = "Petroleum" 
                    local ind_20_1 = "Chemicals"
                    local ind_20_2 = "and Pharma"
                    local ind_22_1 = "Rubber and"
                    local ind_22_2 = "Plastics"
                    local ind_23_1 = "Non-Metallic"
                    local ind_23_2 = "Minerals" 
                    local ind_24_1 = "Basic Metals" 
                    local ind_25_1 = "Fabricated" 
                    local ind_25_2 = "Metals" 
                    local ind_26_1 = "Computer and" 
                    local ind_26_2 = "Electronic" 
                    local ind_27_1 = "Electrical" 
                    local ind_28_1 = "Machinery"
                    local ind_28_2 = "Equipment" 
                    local ind_28_3 = "N.E.C"
                    local ind_29_1 = "Motor"
                    local ind_29_2 = "Vehicles" 
                    local ind_30_1  = "Transport"
                    local ind_30_2  ="Equipment"
                    local ind_31_1 = "Furniture" 
                    local ind_32_1 = "Other"
                    local ind_32_2 = "Manufacturing"
    
                    gen Industry = ""
                    gen Ind = ""
                    forv i = 10/32 { 
                        replace Ind = "`i'" if isic4_str=="`i'" & row==0 
                        forv j = 0/2 { 
                            replace Industry = "`ind_`i'_`=`j'+1''" if isic4_str=="`i'" & row==`j'
                        }
                    }
                    forv i = 1/1 { 
                        qui log using "tfp_index_`estimator'_`sh'_f.txt", t replace 
                        di "\begin{tabular}{lcccccccccc}"
                        di " & Industry & Agg. & 2010 & 2011 & 2012 & 2013 & 2014 & 2015 & 2016 & 2017 \\"
                        di "\hline"
                        qui log close
                    }
                    count
                    local rc = 0
                    forv i = 1/`r(N)' { 
                        local ind = Ind in `i'
                        local industry = Industry in `i'
                        local f = f in `i'
                        
                        local rc = `rc'+1
                        if `rc'==4 { 
                            local rc = 1 
                        }

                        local line = "`ind' & `industry' & `f' "
                        forv j = 2010/2017 { 
                            local a_`j' = 100*tfp_`estimator'_`j'  in `i'
                            local a_`j': di %3.2f `a_`j''
                            local line = "`line' & `a_`j''"
                        }
                        qui log using "tfp_index_`estimator'_`sh'_f.txt", t append	
                        di "`line' \\" 
                        qui log close 
                        if `rc'==3 { 
                            qui log using "tfp_index_`estimator'_`sh'_f.txt", t append	
                            di " \\" 
                            qui log close 
                        }
                    }
                    forv i = 1/1 { 
                        qui log using "tfp_index_`estimator'_`sh'_f.txt", t append	
                        di "\hline"
                        di "\end{tabular}"
                        qui log close 
                    }

                        filefilter tfp_index_`estimator'_`sh'_f.txt atfp_index_`estimator'_`sh'_f.txt, from("\n> ") to("") replace	

                        filefilter atfp_index_`estimator'_`sh'_f.txt tfp_index_`estimator'_`sh'_f.txt, from("\r") to("") replace
                        erase  atfp_index_`estimator'_`sh'_f.txt
                restore
            }
        }
    clear 
    mata: st_matrix("est_mat",est_mat)
    svmat est_mat 
    gen row = _n 
    local obs = 154 
    local coefs = 5 
    tsset row 
    local amon = 1
    cap drop tagme 
    gen tagme =1  
    forv i = 1/14 {
        if `amon'==-1 { 
            replace tagme = 0 if row==`i'
        }
        local amon = `amon'*(-1)
        di `amon'
    }
    forv i = 1/3 {  
    cap drop pval_`i'
    gen pval_`i' = 2*ttail((154-6),abs(est_mat`i'/(f.est_mat`i')))  if row<=11 & tagme==1 
    cap drop star_`i'
    gen star_`i' = "*" if pval_`i'<.1 
    replace star_`i' = "**" if pval_`i'<.05
    replace star_`i' = "***" if pval_`i'<.001
    }
    tostring est_mat1 est_mat2 est_mat3, replace force format(%6.5g)
    forv i = 1/3 { 
        replace est_mat`i' = substr(est_mat`i',1,4)+star_`i'
        replace est_mat`i' = "("+est_mat`i'+")" if tagme==0 & row<=12
    }
    local title = "& ACF \$(\rho) \$ & PRODEST & Wooldridge (KN) \\"
    gen name = "\$ \hat{\beta}_k \$" if row==1 
    replace name = "\$ \hat{\beta}_l \$" if row==3
    replace name = "Aggregate Capital to Labour Index " if row==5
    replace name = " Aggregate Output to Labour Index " if row==7
    replace name = " Aggregate Output to Capital Index " if row==9
    replace name = "Constant" if row==11
    replace name = "Adj. \$ R^2\$" if row==13 
    replace name = "Observations" if row==14 
    count 
    forv i = 1/`r(N)' { 
        if `i'==1 { 
            qui log using "`paperfolder'\\Tables\corrs.txt", t replace 
            di "\begin{tabular}{lccc}"
            di "`title'"
            di "\hline"
        }
        local line_`i' = name in `i'
        forv j = 1/3 { 
            local add = est_mat`j' in `i' 
            local line_`i' = "`line_`i'' & `add'" 
        } 
        local line_`i' = "`line_`i''"
        if `i' ==13 { 
            di "\hline"
        }
        di "`line_`i'' \\"    

        if `i'==14 { 
            di "\hline"
            di "\end{tabular}"
            qui log close 

        }
    }
end
