cap program drop prep_for_figs
    program define prep_for_figs 
    syntax , adr(string) sadr(string) sname(string)  indvar(string) digits(string)
        clear
        cd "`adr'"
        local dr = "`adr'"
        local files : dir "`dr'" files "manuf*.dta"
        foreach file in `files' {
            if regexm("`file'","_fs_")==0 {
                append using `file'
                cap gen source = "`file'" 
                cap replace source = "`file'" if source==""	
            }
        }
        label var bl "Labour Coef."
        label var bk "Capital Coef."
        foreach est in basic grid altinit basic_pe basica { 
            replace est = "`est'_bs_IV" if est=="`est'_IV_bs"
        }
        replace est = "prodest_acf_IV" if est=="prodest_acf_ch"
        replace est = "prodest_wrdg_IV" if est=="prodest_wrdg_ch"
		if `digits'==3 { 
            gen comp_prof_sic5_3d = ind
            destring comp_prof_sic5_3d, replace force
            merge m:1 comp_prof_sic5_3d using D:\\3digit_isic4.dta, keep(master matched)
           keep if _merge==3
        }
        else { 
            destring(ind), gen(isic4)
        }
        levelsof est, local(es)
        levelsof est_type, local(esttype)
        save params2.dta , replace
        foreach est of local es { 
            foreach est_type of local esttype { 
                use params2, clear 
                keep if est=="`est'" & est_type=="`est_type'"
                forv ind=10/32 { 
                    preserve 
                    keep if isic4==`ind'
                    gen n = _n 
                    foreach var in bk bl {
                        replace `var' = -.1 if `var'<0 & `var'>-.5  
                        replace `var' = -.15 if `var'<=-.5 & `var'>-1  
                        replace `var' = -.2 if `var'<=-1 & `var'>-2  
                        replace `var' = -.25 if `var'<=-2  
                        replace `var' = 1.1 if `var'<1.5 & `var'>1  
                        replace `var' = 1.15 if `var'<2 & `var'>=1.5  
                        replace `var' = 1.2 if `var'<3 & `var'>=2  
                        replace `var' = 1.25 if `var'>=3 & `var'!=.  
                    }
                    rename bl bl_`ind'
                    rename bk bk_`ind'
                    rename isic4 isic4_`ind'
                    save test_`ind', replace 
                    restore 
                }		
                local counter = 0 
                forv ind = 10/32 {
                    if `counter'==0 { 
                        use test_`ind', clear 
                        local counter = 1 
                        erase test_`ind'.dta
                    }
                    else { 
                        merge 1:1 n using test_`ind', nogen
                        erase test_`ind'.dta				
                    }
                    
                }
                export delimited using "`sadr'\\`sname'_`est'_`est_type'.csv", replace
            }
        }
        cap erase "`adr'\\params2.dta" 
    end
   
    cap program drop prep_for_figs_over
    program define prep_for_figs_over 
    syntax , adr(string) sdir(string) [levels(integer 3)] indvar(string) digits(string)
    cd "`adr'"
    local subfolders: dir "`adr'" dirs "*" 
    cap mkdir "`sdir'"
    foreach flder of local subfolders {
        cap mkdir "`sdir'\\"
        local subfolder2: dir "`adr'\\`flder'" dirs "*"         
        foreach ss of local subfolder2 {
            local subfolder3: dir "`adr'\\`flder'\\`ss'" dirs "*"
            foreach ss2 of local subfolder3 {
                local subfolder4: dir "`adr'\\`flder'\\`ss'\\`ss2'\\" dirs "*"
                foreach ss3  of local subfolder4 {
                    prep_for_figs, adr("`adr'\\`flder'\\`ss'\\`ss2'\\`ss3'") sadr("`sdir'") sname("`flder'_`ss'_`ss2'_`ss3'") indvar(`indvar') digits(`digits')
                }
            }
        }
    }
    end
