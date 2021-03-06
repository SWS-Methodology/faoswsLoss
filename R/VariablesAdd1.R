#' Part of the FAO Loss Module
#' 
#' @author Alicia English
#' @export VariablesAdd1


VariablesAdd1 <- function(DataUseInt,keys_lower,Predvar2,Impute,fgroup,CountryGroup,fbsTree,Temperature,Precipitation,CropCalendar,LossTables_Yr,LossTables_ctryYr){  
  # Description:
  #Adds the explanatory variables to the dataset for either the estimation model or the predictive set
  # inputs:
  # DataUseInt ~ The dataset for either the estimation model or the predictive set
  # keys ~ The consistent set to model on ("geographicaream49", )
  # Predvar ~ are for the prediction dataset in order to only include the minimum variables 
  Predvar <- unique(c(Predvar2,names(DataUseInt)))
  if(length(Predvar2)>0){
    dropExtra = TRUE
    
  }else{
    dropExtra = FALSE
    
  }
  DataUseInt$geographicaream49 <- as.integer(DataUseInt$geographicaream49)
  DataUseInt$measureditemcpc <- as.character(DataUseInt$measureditemcpc)
  DataUseInt$timepointyears <- as.integer(DataUseInt$timepointyears)
  
  names(DataUseInt) <-tolower(names(DataUseInt))
  ## Imputation function for data
  x_impute <- function(x, fun) {
    x[is.na(x)] <- fun(x, na.rm = TRUE)
    return(x)
  } 
  
  # if(LocalRun){
  #   CountryGroup <- as.data.table(read.csv(paste(githubsite, 'General/a2017regionalgroupings_SDG_02Feb2017.csv', sep='')))
  #   Temperature <-  as.data.table(read.csv(paste(githubsite, 'General/Temp_climate.csv', sep='')))
  #   Precipitation <- as.data.table(read.csv(paste(githubsite, 'General/Rain_climate.csv', sep='')))
  #   CropCalendar <- as.data.table(read.csv(paste(githubsite, 'General/AllCropCalendar.csv', sep='')))
  #   load(paste(githubsite, 'General/fbsTree.RData',sep=""))
  #   
  #   names(CountryGroup) <- tolower(names(CountryGroup))
  #   names(Temperature) <- tolower(names(Temperature))
  #   names(Precipitation) <- tolower(names(Precipitation))
  #   names(CropCalendar) <- tolower(names(CropCalendar))
  #   names(fbsTree) <- tolower(names(fbsTree))
  #   
  # }else{
  #   CountryGroup <- ReadDatatable("a2017regionalgroupings_sdg_feb2017")
  #   fbsTree <- ReadDatatable("fbs_tree")
  #   Temperature <-  ReadDatatable("temp_climate_month_ctry")
  #   Precipitation <- ReadDatatable("rain_climate_month_ctry")
  #   CropCalendar <- ReadDatatable("crop_calendar_nov17")
  #   
  # }
  names(CountryGroup) <- tolower(names(CountryGroup))
  CountryGroup$country = CountryGroup$m49_region
  CountryGroup$country <- tolower(CountryGroup$country)

  
  CountryGroup[,"geographicaream49":=CountryGroup$m49_code]
  CountryGroup$geographicaream49 <- as.integer(CountryGroup$geographicaream49)
  CropCalendar$geographicaream49 <- as.integer(CropCalendar$geographicaream49)

  names(CountryGroup) <- gsub("[[:punct:]]","_",names(CountryGroup))
  
  DataUseInt <- merge(DataUseInt , CountryGroup[, c('geographicaream49', 'isocode'), with=FALSE], by.x = c("geographicaream49"),
                      by.y = c("geographicaream49"), all.x = TRUE, all.y = FALSE)

  DataUseInt[,lag1yr:= timepointyears - 1]
  DataUseInt[,lag2yr:= timepointyears - 2]
  DataUseInt[,lag3yr:= timepointyears - 3]
  Predvar <- c(Predvar,"lag1yr","lag2yr","lag3yr")
  
  #####FAO SWS Datasets#####
  names(fbsTree)[names(fbsTree)== "id3"] <- "foodgroupname"
  names(fbsTree)[names(fbsTree)== "measureditemsuafbs"|names(fbsTree)== "item_sua_fbs" ] <- "measureditemcpc"
  DataUseInt <- join(DataUseInt, fbsTree, by = c("measureditemcpc"),type= 'left', match='all')
  
  ######## Weather Data  ################ 

  ConvFactor_calYr <- unique(DataUseInt[, c("timepointyears"), with=FALSE])
  ConvFactor_cal <- unique(DataUseInt[, c("geographicaream49", "timepointyears"), with=FALSE])
  ConvFactor_cal2 <- unique(DataUseInt[,keys_lower ,with=FALSE])
  names(ConvFactor_cal) <- tolower(names(ConvFactor_cal))
  names(ConvFactor_calYr) <- tolower(names(ConvFactor_calYr))
  ConvFactor_cal$geographicaream49 <- as.integer(ConvFactor_cal$geographicaream49)

  if(!any(fgroup %in% c("2943", "2946","2945","2949","2948"))){   
    names(Temperature)[names(Temperature) == 'year'] <- "timepointyears"
    Temperature <- merge( Temperature , CountryGroup[,c("geographicaream49", "isocode"), with=FALSE], by.x = c('isocode'),
                        by.y = c('isocode'), all.x = TRUE, all.y = FALSE)
    
    Temperature <-Temperature %>% filter(geographicaream49 %in%  ConvFactor_cal$geographicaream49  & timepointyears %in%  ConvFactor_cal$timepointyears)
    
    names(Precipitation)[names(Precipitation) == 'year'] <- "timepointyears"
    Precipitation <- merge(Precipitation, CountryGroup[,c("geographicaream49", "isocode"), with=FALSE], by.x = c('isocode'),
                          by.y = c('isocode'), all.x = TRUE, all.y = FALSE)
    Precipitation <-Precipitation %>% filter(geographicaream49 %in%  unique(ConvFactor_cal$geographicaream49)  & timepointyears %in%  unique(ConvFactor_cal$timepointyears))
    
    CropCalendar <- merge(CropCalendar, CountryGroup[,c("geographicaream49", "isocode"), with=FALSE], by.x = c("geographicaream49"),
                           by.y = c("geographicaream49"), all.x = TRUE, all.y = FALSE)
    
    CropCalendar <- CropCalendar[, c("geographicaream49","measureditemcpc","crop", "harvesting_month_onset", "harvesting_month_end"), with=FALSE]
    CropCalendar$measureditemcpc <- addHeadingsCPC(CropCalendar$measureditemcpc) 
    CropCalendar$crop <- tolower(CropCalendar$crop)
    CropCalendar <- CropCalendar %>% arrange(geographicaream49, -harvesting_month_end) %>% 
                                    filter(!is.na(harvesting_month_end))
    
    AggCropCalendar <- as.data.table(aggregate(harvesting_month_end ~ geographicaream49+measureditemcpc, data = CropCalendar, min))
    AggCropCalendar <- merge(ConvFactor_cal2,AggCropCalendar, by= c('geographicaream49','measureditemcpc'), all.x = TRUE, all.y = FALSE)
    names(AggCropCalendar)[names(AggCropCalendar) == 'harvesting_month_end'] <- 'month'
    
    if(length(na.omit(AggCropCalendar$month))>0){
      Temperature2 <- join(AggCropCalendar, Temperature, by= c('geographicaream49','timepointyears', 'month'),type= 'left', match='all')
      Precipitation2 <- join(AggCropCalendar, Precipitation , by= c('geographicaream49','timepointyears', 'month'),type= 'left', match='all')
      
      if(length(na.omit(Temperature2$temperature_c)) >0){
         tempPred <- lm(temperature_c ~geographicaream49 + timepointyears+ month,Temperature2)
         Temperature2[is.na(temperature_c)&!is.na(month),temperature_c := coefficients(tempPred)[1] +
                        if(dim(Temperature2[is.na(temperature_c)&!is.na(month)])[1]>2){
                         rowSums(mapply(`*`,coefficients(tempPred)[-1],Temperature2[is.na(temperature_c)&!is.na(month) ,names(coefficients(tempPred)[-1]),with=F]), na.rm=TRUE)
                        }else{
                          sum(mapply(`*`,coefficients(tempPred)[-1],Temperature2[is.na(temperature_c)&!is.na(month) ,names(coefficients(tempPred)[-1]),with=F]),na.rm = T)
                        }]
         DataUseInt <- merge(DataUseInt, Temperature2, by = keys_lower, all.x = TRUE)  
      }
      if(length(na.omit(Precipitation2$rainfall_mm)) >0){
        PrecPred <-  lm(rainfall_mm ~geographicaream49 + timepointyears+ month,Precipitation2)
        Precipitation2[is.na(rainfall_mm)&!is.na(month),rainfall_mm := coefficients(PrecPred)[1] +
                        if(dim(Precipitation2[is.na(rainfall_mm)&!is.na(month)])[1]>2){ 
                         rowSums(mapply(`*`,coefficients(PrecPred)[-1],Precipitation2[is.na(rainfall_mm)&!is.na(month) ,names(coefficients(PrecPred)[-1]),with=F]), na.rm=TRUE)
                        }else{
                          sum(mapply(`*`,coefficients(PrecPred)[-1],Precipitation2[is.na(rainfall_mm)&!is.na(month) ,names(coefficients(PrecPred)[-1]),with=F]), na.rm=TRUE)
                        }]
        DataUseInt <- merge(DataUseInt, Precipitation2,by = keys_lower, all.x = TRUE)  
      }
      
    }else{
        DataUseInt <-DataUseInt}
  }
  DataUseInt$geographicaream49 <- as.integer(DataUseInt$geographicaream49)
 
  names(DataUseInt) <- gsub("[[:punct:]]","_",names(DataUseInt))
  if(dropExtra){
    keepForPred <- names(DataUseInt)[names(DataUseInt) %in% Predvar]
    DataUseInt <- DataUseInt[,keepForPred, with=FALSE]
  }
  ####Import and merge By Year ###############
  if(LocalRun){
    LossTablelist_Yr = dir("~/faoswsLoss/data-raw/byYear/",
                full.names = TRUE) 

    pb <- txtProgressBar()
    for (ii in seq_len(length(LossTablelist_Yr))){
      i = ii /length(LossTablelist_Yr)
      setTxtProgressBar(pb, i)
      ConvFactor_calYr <-merge(ConvFactor_calYr, read_csv(LossTablelist_Yr[ii]), 
                               by.x =c("timepointyears"), by.y =c( "timepointyears"), all.x = TRUE, all.y = FALSE)
      ConvFactor_calYr <- ConvFactor_calYr %>% subset(., select=which(!duplicated(names(.)))) 
      
    }
     }else{
      # LossTablelist_Yr <- c('world_bank_pinksheets')
      pb <- txtProgressBar()
      for (ii in seq_len(length(LossTablelist_Yr))){
        i = ii /length(LossTablelist_Yr)
        setTxtProgressBar(pb, i)
        ConvFactor_calYr <-merge(ConvFactor_calYr, LossTables_Yr[[LossTablelist_Yr[ii]]], 
                                 by.x =c("timepointyears"), by.y =c( "timepointyears"), all.x = TRUE, all.y = FALSE)
        ConvFactor_calYr <- ConvFactor_calYr %>% subset(., select=which(!duplicated(names(.)))) 
        
      }
  }
  
  ConvFactor_calYr[, oilave:=rowMeans(.SD, na.rm=TRUE), .SDcols=c("crude_petro","crude_brent","crude_dubai","crude_wti")]
  ConvFactor_calYr[, coalave:=rowMeans(.SD, na.rm=TRUE), .SDcols=c("coal_aus","coal_col","coal_safrica")]
  ConvFactor_calYr[, natgasave:=rowMeans(.SD, na.rm=TRUE), .SDcols=c("ngas_us","ngas_eur","ngas_jp", "inatgas")]
  AvePs <- c("crude_petro","crude_brent","crude_dubai","crude_wti","coal_aus","coal_col","coal_safrica","ngas_us","ngas_eur","ngas_jp","inatgas")
  ConvFactor_calYr[,  (AvePs):= NULL,]
  ## Load first all the data tables and merges with the time and country set from the training or predicitve set and then merge with the data 

    DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    DataUseInt  <-  merge(DataUseInt,  ConvFactor_calYr, by.x = c("timepointyears"),  by.y = c("timepointyears"),type= 'left', match='all')
    DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    
    a <- dim(DataUseInt)[2]
    DataUseInt  <-  merge(DataUseInt,  ConvFactor_calYr, by.x = c('lag1yr'), by.y = c("timepointyears"), all.x = TRUE, all.y = FALSE)
    colnames(DataUseInt)[(a+1):dim(DataUseInt)[2]]  = paste(colnames(ConvFactor_calYr)[!(colnames(ConvFactor_calYr) %in% c("timepointyears"))],'lag1yr', sep='_')
    DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    
    a <- dim(DataUseInt)[2]
    DataUseInt  <-  merge(DataUseInt,  ConvFactor_calYr, by.x = c('lag2yr'), by.y = c("timepointyears"), all.x = TRUE, all.y = FALSE)
    colnames(DataUseInt)[(a+1):dim(DataUseInt)[2]]  = paste(colnames(ConvFactor_calYr)[!(colnames(ConvFactor_calYr) %in% c("timepointyears"))],'lag2yr', sep='_')
    DataUseInt <-DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    
    a <- dim(DataUseInt)[2]
    DataUseInt  <-  merge(DataUseInt,  ConvFactor_calYr, by.x = c( 'lag3yr'), by.y = c("timepointyears"), all.x = TRUE, all.y = FALSE)
    colnames(DataUseInt)[(a+1):dim(DataUseInt)[2]]  = paste(colnames(ConvFactor_calYr)[!(colnames(ConvFactor_calYr) %in% c("timepointyears"))],'lag3yr', sep='_')
    DataUseInt <-DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    
    names(DataUseInt) <- gsub("[[:punct:]]","_",names(DataUseInt)) 
    if(dropExtra){
      keepForPred <- names(DataUseInt)[names(DataUseInt) %in% Predvar]
      DataUseInt <- DataUseInt[,keepForPred, with=FALSE]
    }

    drops = c('Area_Code',
              'Domain',  
              'Element',
              'Flag',
              'ISOCode',
              'item_code',
              'Unit',
              'description',
              'descriptoin',
              "area_code"
              
    )

    ####Import and merge By Year & country ###############
    # LossTablelist_ctryYr <- c('bm_gsr_fcty_cd',
    #                           'bm_gsr_totl_cd',
    #                           'bm_trf_prvt_cd',
    #                           'bn_gsr_fcty_cd',
    #                           'bn_trf_curr_cd',
    #                           'bx_gsr_fcty_cd',
    #                           'bx_gsr_totl_cd',
    #                           'bx_trf_curr_cd',
    #                           'dt_dod_dect_ex_zs',
    #                           'dt_dod_dstc_xp_zs',
    #                           'dt_dod_pvlx_ex_zs',
    #                           'dt_int_dect_ex_zs',
    #                           'dt_oda_odat_mp_zs',
    #                           'dt_tds_dect_ex_zs',
    #                           'dt_tds_dppf_xp_zs',
    #                           'dt_tds_dppg_xp_zs',
    #                           'eg_elc_accs_zs',
    #                           'gc_tax_ypkg_cn',
    #                           'gc_tax_ypkg_rv_zs',
    #                           'gc_tax_ypkg_zs',
    #                           'ny_adj_nnty_cd',
    #                           ## 'ny_adj_nnty_kd',
    #                           'ny_adj_nnty_kd_zg',
    #                           'ny_adj_nnty_pc_cd',
    #                           'ny_adj_nnty_pc_kd',
    #                           'ny_adj_nnty_pc_kd_zg',
    #                           ## 'ny_gdy_totl_kn',
    #                           'ny_gsr_nfcy_cd',
    #                           'ny_gsr_nfcy_cn',
    #                           'ny_gsr_nfcy_kn',
    #                           'si_dst_02nd_20',
    #                           'si_dst_03rd_20',
    #                           'si_dst_04th_20',
    #                           'si_dst_05th_20',
    #                           'si_dst_10th_10',
    #                           'si_dst_frst_10',
    #                           'si_dst_frst_20',
    #                           'si_spr_pc40',
    #                           'si_spr_pc40_zg',
    #                           'si_spr_pcap',
    #                           'si_spr_pcap_zg',
    #                           'tm_val_mrch_hi_zs',
    #                           'tm_val_mrch_or_zs',
    #                           'tm_val_mrch_r1_zs',
    #                           'tm_val_mrch_r2_zs',
    #                           'tm_val_mrch_r3_zs',
    #                           'tm_val_mrch_r5_zs',
    #                           'tm_val_mrch_r6_zs',
    #                           'tm_val_mrch_wr_zs',
    #                           'tx_val_mrch_hi_zs',
    #                           'tx_val_mrch_or_zs',
    #                           'tx_val_mrch_r1_zs',
    #                           'tx_val_mrch_r2_zs',
    #                           'tx_val_mrch_r3_zs',
    #                           'tx_val_mrch_r4_zs',
    #                           'tx_val_mrch_r5_zs',
    #                           'tx_val_mrch_r6_zs',
    #                           'tx_val_mrch_wr_zs',
    #                           'wp_time_01_8',
    #                           'wp_time_01_9',
    #                           'wp15163_4_8',
    #                           'wp15163_4_9',
    #                           'credittoag',
    #                           'investment_consumptionfixedcapital',
    #                           'investment_grosscapitalstocks',
    #                           'investment_grossfixedcapitalformation_usd',
    #                           'investment_netcapitalstocks',
    #                           'ironsteelimport7055475',
    #                           'lpidata',
    #                           'sankey_diagram_iea20apr17',
    #                           'spendingonag_ifpri_com'
    # )

    ## Load first all the data tables and merges with the time and country set from the training or predicitve set and then merge with the data 
    if(LocalRun){
      LossTablelist_Yr = dir("~/faoswsLoss/data-raw/byCtryYear/",
                    full.names = TRUE) 
      
      pb <- txtProgressBar()
      for (ii in seq_len(length(LossTablelist_Yr))){
        i = ii /length(LossTablelist_Yr)
        setTxtProgressBar(pb, i)
        ConvFactor_cal <-merge(ConvFactor_cal,  read_csv(LossTablelist_Yr[ii]), 
                               by.x =c("geographicaream49", "timepointyears"), by.y =c("geographicaream49", "timepointyears"), all.x = TRUE, all.y = FALSE)
        ConvFactor_cal <- ConvFactor_cal%>% subset(., select=which(!duplicated(names(.)))) 
        
      }
    }else{
      pb <- txtProgressBar()
      for (ii in seq_len(length(LossTablelist_ctryYr))){
        i = ii /length(LossTablelist_ctryYr)
        setTxtProgressBar(pb, i)
        ConvFactor_cal <-merge(ConvFactor_cal, LossTables_ctryYr[[LossTablelist_ctryYr[ii]]], 
                     by.x =c("geographicaream49", "timepointyears"), by.y =c("geographicaream49", "timepointyears"), all.x = TRUE, all.y = FALSE)
        ConvFactor_cal <- ConvFactor_cal%>% subset(., select=which(!duplicated(names(.)))) 
  
      }
      close(pb)
    }
    if(length(drops[drops  %in% names(ConvFactor_cal)])>0){
      for(rx in 1:length(drops)){
      drops = c(drops,names(ConvFactor_cal)[grep(tolower(drops[rx]),names(ConvFactor_cal))])
      }
      drops = unique(drops)
      ConvFactor_cal[,drops[drops  %in% names(ConvFactor_cal)] :=NULL]
    }
    nums2 <- !sapply(ConvFactor_cal, is.numeric)
    nums2[names(nums2) == "geographicaream49"] <- FALSE
    nums2[names(nums2) == "timepointyears"] <- FALSE
    NonNumeric <- names(nums2)[nums2 == TRUE]
    ConvFactor_cal <- ConvFactor_cal[,(NonNumeric):=NULL]
    
    convnames <- c(names(ConvFactor_cal),paste(names(ConvFactor_cal),'lag1yr', sep='_'), paste(names(ConvFactor_cal),'lag2yr', sep='_'),paste(names(ConvFactor_cal),'lag3yr', sep='_') )
    keepname <- convnames[convnames %in% Predvar]
    keepname <- gsub("_lag1yr","",keepname)
    keepname <- gsub("_lag2yr","",keepname)
    keepname <- gsub("_lag3yr","",keepname)
    
    if(length(keepname) >2 ){
    ConvFactor_cal <- ConvFactor_cal[,unique(c("geographicaream49","timepointyears", keepname)),with=F]
  
    DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    DataUseInt <- join(DataUseInt, ConvFactor_cal, by = c("geographicaream49", "timepointyears"),type= 'left', match="first")
    DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    
    a <- dim(DataUseInt)[2]
    names(ConvFactor_cal)[ names(ConvFactor_cal) == "timepointyears" ] <- 'lag1yr'
    DataUseInt  <-  join(DataUseInt,  ConvFactor_cal, by= c("geographicaream49", 'lag1yr'),type= 'left', match="first")
    names(DataUseInt) <- c(names(DataUseInt)[1:a], paste(names(ConvFactor_cal)[!names(ConvFactor_cal) %in% c("geographicaream49",'lag1yr')],'lag1yr', sep='_'))
    DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    
    a <- dim(DataUseInt)[2]
    names(ConvFactor_cal)[ names(ConvFactor_cal) == 'lag1yr'] <- 'lag2yr'
    DataUseInt  <- join(DataUseInt,  ConvFactor_cal, by = c("geographicaream49", 'lag2yr'),type= 'left', match="first")
    names(DataUseInt) <- c(names(DataUseInt)[1:a], paste(names(ConvFactor_cal)[!names(ConvFactor_cal) %in% c("geographicaream49",'lag2yr')],'lag2yr', sep='_'))
    DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    
    a <- dim(DataUseInt)[2]
    names(ConvFactor_cal)[ names(ConvFactor_cal) == 'lag2yr'] <- 'lag3yr'
    DataUseInt  <- join(DataUseInt, ConvFactor_cal, by = c("geographicaream49", 'lag3yr'),type= 'left', match="first")
    names(DataUseInt) <- c(names(DataUseInt)[1:a], paste(names(ConvFactor_cal)[!names(ConvFactor_cal) %in% c("geographicaream49",'lag3yr')],'lag3yr', sep='_'))
    DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    }
    if(dropExtra == FALSE){
  
      DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
      DataUseInt <- join(DataUseInt, ConvFactor_cal, by = c("geographicaream49", "timepointyears"),type= 'left', match="first")
      DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
      
      a <- dim(DataUseInt)[2]
      names(ConvFactor_cal)[ names(ConvFactor_cal) == "timepointyears" ] <- 'lag1yr'
      DataUseInt  <-  join(DataUseInt,  ConvFactor_cal, by= c("geographicaream49", 'lag1yr'),type= 'left', match="first")
      names(DataUseInt) <- c(names(DataUseInt)[1:a], paste(names(ConvFactor_cal)[!names(ConvFactor_cal) %in% c("geographicaream49",'lag1yr')],'lag1yr', sep='_'))
      DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
      
      a <- dim(DataUseInt)[2]
      names(ConvFactor_cal)[ names(ConvFactor_cal) == 'lag1yr'] <- 'lag2yr'
      DataUseInt  <- join(DataUseInt,  ConvFactor_cal, by = c("geographicaream49", 'lag2yr'),type= 'left', match="first")
      names(DataUseInt) <- c(names(DataUseInt)[1:a], paste(names(ConvFactor_cal)[!names(ConvFactor_cal) %in% c("geographicaream49",'lag2yr')],'lag2yr', sep='_'))
      DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
      
      a <- dim(DataUseInt)[2]
      names(ConvFactor_cal)[ names(ConvFactor_cal) == 'lag2yr'] <- 'lag3yr'
      DataUseInt  <- join(DataUseInt, ConvFactor_cal, by = c("geographicaream49", 'lag3yr'),type= 'left', match="first")
      names(DataUseInt) <- c(names(DataUseInt)[1:a], paste(names(ConvFactor_cal)[!names(ConvFactor_cal) %in% c("geographicaream49",'lag3yr')],'lag3yr', sep='_'))
      DataUseInt <- DataUseInt %>% subset(., select=which(!duplicated(names(.)))) 
    }
    
    
    names(DataUseInt) <- gsub("[[:punct:]]","_",names(DataUseInt))
    
    
    lagyr <- c("lag1yr","lag2yr","lag3yr","lag1yr_lag1yr","lag2yr_lag2yr","lag3yr_lag3yr")
    if(length(lagyr[lagyr %in% names(DataUseInt)])>0){
      DataUseInt[,(lagyr[lagyr %in% names(DataUseInt)]) := NULL ]
    }
    
    DataUseInt$geographicaream49 <- as.character(DataUseInt$geographicaream49)
    
    if(dropExtra){
      keepForPred <- names(DataUseInt)[names(DataUseInt) %in% Predvar]
      DataUseInt <-DataUseInt[,keepForPred, with=FALSE]
    }
    # # Drop the remaining descriptive var
    # drops <-tolower(drops)
    # names(DataUseInt) <- tolower(names(DataUseInt))
    # drops[drops %in% names(DataUseInt)]

    DataUseInt[DataUseInt == ""] = NA
    ##################Imputatuion of dataset#########################
    VarNames <- names(DataUseInt)
    VarNames <- VarNames[!VarNames %in% c("geographicaream49","timepointyears","measureditemcpc","country","crop","loss_per_clean","fsc_location" ,"id1" ,"protected", 
                                          "value_measuredelement_5016", "value_measuredelement_5126", "flagcombination","flagobservationstatus" ,"flagmethod" ,
                                          "id2","foodgroupname","id4","month_x", "temperature_c" , "month_y" ,  "rainfall_mm")]
    
    VarNames <- na.omit(VarNames)
    if(Impute != FALSE & length(VarNames) >0  ){
    
      
      for(ir in 1:length(VarNames)){
        where.na <- which(DataUseInt[ ,VarNames[ir],with=F ]=="NULL" )
        if(length(where.na)>0){
          DataUseInt[,VarNames[ir]] <- as.numeric(DataUseInt[[VarNames[ir]]])
        }
        DataUseInt[where.na,VarNames[ir]] <- NA
      }
      pb <- txtProgressBar()
      ii=0
      
      if(Impute == "ctry"){
        for(irr in 1:length(VarNames)){
          for( j in unique(DataUseInt$geographicaream49)){
            i = ii /(length(unique(DataUseInt$geographicaream49))*length(VarNames))
            setTxtProgressBar(pb, i)
            
            DataUseInt[geographicaream49 == j,VarNames[irr]] <- with(DataUseInt[geographicaream49 ==j,],  x_impute(DataUseInt[[VarNames[irr]]], mean))
            #DataUseInt[,VarNames[ir]] <- na.approx(DataUseInt[,VarNames[ir],with=FALSE], na.rm = T)
            ii =ii+1
          }}
      }  
      if(Impute == "var"){
        for(irr in 1:length(VarNames)){
            DataUseInt[,VarNames[irr]] <- with(DataUseInt, x_impute(DataUseInt[[VarNames[irr]]], mean))
          } 
      }
      }
    
    ########### Principal Component Analysis #### 
    nums1 <- sapply(DataUseInt, is.numeric)
    if(!dropExtra){
    #Makes the columns numeric and looks at correlated variables
    
    dropCV <- list()
    stop = length(colnames(DataUseInt))
    ii = 1
    while(ii){
      nam = colnames(DataUseInt)[ii]
      if(is.na(nam)){break}
      if(sapply(DataUseInt[,nam,with=F],class)== "numeric"){ 
        corrV  <- cor(DataUseInt[,nam,with=F],DataUseInt[,colnames(DataUseInt) %in% names(nums1[nums1==T]) ,with=F],use="pairwise.complete.obs")
        corrV2 <- colnames(corrV)[corrV >.85]
        corrV2  <- corrV2[!corrV2 %in% c(keys_lower,nam)]
        dropCV <- c(dropCV,na.omit(corrV2))
        if(length(unique(na.omit(corrV2))) >0){
          DataUseInt[,c(na.omit(unique(corrV2))):= NULL]
          nums1 <- sapply(DataUseInt, is.numeric)
        }}
      ii =ii +1
      
    }


    }
    nums1[tolower(keys_lower)] <- TRUE
    nums1[names(nums1) == "sdg_regions"]<- TRUE
    explanatory <- names(nums1)[nums1 == TRUE]
    
    if("fsc_location" %in% names(DataUseInt)){
      explanatory <- c(explanatory,"foodgroupname", "fsc_location")
      }else{ 
      explanatory <- c(explanatory,"foodgroupname")
      
      }
    explanatory <-explanatory[explanatory %in% names(DataUseInt)]  
    DataUseInt <-  DataUseInt[ , explanatory ,with=FALSE]
    ###### Dimension Expansion #########
    #if(length(colnames(DataUseInt))<20){
   #   DataUseInt <-MultiExp(DataUseInt, 2,"loss_per_clean")
   # }  
    
  return(DataUseInt)  
}  
