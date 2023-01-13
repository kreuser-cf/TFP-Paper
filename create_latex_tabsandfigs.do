gl paperfolder = "C:\Users\Friedrich\Dropbox\UNUWIDER\TFP_Paper_Submitted\"
gl dofiles = "C:\Users\Friedrich\Dropbox\UNUWIDER\TFP_Paper_Submitted\finalcode\"
gl main_out_folder = "${paperfolder}\\OutputData\\2021-06-25\\"
gl vrs = "d19"
set linesize 255
/* We use the following code for  estimatiation */
*  These are run on the server 
*    do "${dofiles}\\create_data.do"
 *   do "${dofiles}\\prod_bat_par_19.do"
    * The TFP distribution figures are created by 
 *   do "${dofiles}\\tfp_pct2.do" 
 
* get the coefficient tables
    do "${dofiles}\\get_coefs.do"
* generate the aggregates tables 
    do "${dofiles}\\TFP_Aggregates_Latex.do"
    
    tfp_aggregates, paperfolder("${paperfolder}")

    do "${dofiles}\\prep_for_figures.do"
    foreach poly in p3  { 
        local adr = "${main_out_folder}\\output_p3_isic4_str_${vrs}"
        cap mkdir "${paperfolder}\\FigData\\"
            cap mkdir "${paperfolder}\\FigData\\`poly'_isic4_${vrs}\\"
        
            cap mkdir "${paperfolder}\\figs\\"
            cap mkdir "${paperfolder}\\figs\\`poly'_isic4_${vrs}\\"
            local sadr =  "${paperfolder}\\FigData\\`poly'_isic4_${vrs}\\"   
        prep_for_figs_over , adr("`adr'") sdir("`sadr'") indvar(isic4) digits(2)
    } 
    * The scatter plots are created in python with scatter_figs.py

    * This creates figure 2
    do "${dofiles}\\compare_coefs.do"
    
    do "${dofiles}\\sum_aggs.do"

