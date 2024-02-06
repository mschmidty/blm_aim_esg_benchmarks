calc_benchmarks_by_esg_using_tdat_data<-function(tdat_esg, indicators){
  funcs<-c("_n", "_min", "_q25", "_q50","_q75", "_max", "_sd", "_count_in_calc")

  select_names<-c()

  for(x in indicators){
    for(y in funcs){
      select_names<-c(select_names, paste0(x,y))
    }
  }

  ## These indicators have lots of zeros!!!! 
  zero_inflated<- c("AH_NoxAnnGrassCover", "AH_NoxCover", "AH_NonNoxTreeCover", "NumSpp_NoxPlant", "AH_SagebrushCover", "GapCover_200_plus", "AH_NonNoxPerenForbCover", "GapCover_101_200", "pct_sagebrush_dead", "BareSoilCover")
  

  tdat_esg%>%
    mutate_at(zero_inflated, ~na_if(.,0))%>%
    group_by(ESG)%>%
    summarize_at(
      .vars=indicators, 
      .funs=list(
        n=length,
        count_in_calc=~sum(!is.na(.x)),
        min =  ~ min(.x, na.rm=T),
        q25 = ~quantile(.x, probs=0.25, na.rm=T),
        q50 = ~quantile(.x, probs=0.5, na.rm=T),
        q75 = ~quantile(.x, probs=0.75, na.rm=T),
        max = ~ max(.x, na.rm=T),
        sd = ~sd(.x,na.rm=T)
      )
    )%>%
    ungroup()%>%
    select(ESG, n=BareSoilCover_n,all_of(select_names))%>%
    select(-matches("_n$"))%>%
    arrange(desc(n))%>%
    pivot_longer(cols=BareSoilCover_min:FH_WoodyAndHerbLitterCover_count_in_calc, names_to="indicator", values_to="value")%>%
    mutate(
      value=ifelse(n<5,NA, value),
      indicator_parent = str_extract(indicator, ".+?(?=_count_in_calc|_q25|_q50|_q75|_sd|_min|_max)"),
      directional_indicator = case_when(
        str_detect(indicator, "min") ~ "min",
        str_detect(indicator, "q25") ~ "q25",
        str_detect(indicator, "q50") ~ "q50",
        str_detect(indicator, "q75") ~ "q75",
        str_detect(indicator, "max") ~ "max",
        str_detect(indicator, "sd") ~ "sd",
        str_detect(indicator, "count_in_calc")~ "n"
      )
    )%>%
    mutate(value = ifelse(indicator_parent %in% zero_inflated & directional_indicator=="min", 0, value))%>%
    select(ESG, value, indicator_parent, directional_indicator)%>%
    pivot_wider(names_from=directional_indicator, values_from=value)%>%
    rename(indicator=indicator_parent)
}

### Consider revisiting this. 
determine_indicator_direction_of_ranking<-function(){
    low_marginal<-tibble(var_low_marginal=c( 
      "AH_NonNoxTreeCover"
    ))%>%
    rename(indicator=1)%>%
    mutate(type="low_marginal")

  high_marginal<-tibble(var_high_marginal=c(
      "TotalFoliarCover",
      "AH_SagebrushCover",
      "Hgt_Sagebrush_Avg",
      "FH_WoodyAndHerbLitterCover",
      "AH_NonNoxShrubCover"
    ))%>%
    rename(indicator=1)%>%
    mutate(type="high_marginal")

  high_suitable<-tibble(var_high_suitable = c(
      "AH_NonNoxPerenForbCover",
      "Hgt_PerenForb_Avg",
      "AH_NonNoxPerenGrassCover",
      "Hgt_NonNoxPerenGrass_Avg",
      "SoilStability_Protected",
      "SoilStability_Unprotected"
    ))%>%
    rename(indicator=1)%>%
    mutate(type="high_suitable")

  low_suitable<-tibble(var_low_suitable=c(
      "BareSoilCover",
      "pct_sagebrush_dead",
      "NumSpp_NoxPlant",
      "GapCover_25_plus",
      "GapCover_101_200",
      "GapCover_200_plus"
    ))%>%
    rename(indicator=1)%>%
    mutate(type="low_suitable")

  low_suitable_single_q<-tibble(var_low_suitable_single_q=c(
    "AH_NoxCover",
    "AH_NoxAnnGrassCover"
  ))%>%
  rename(indicator=1)%>%
  mutate(type="low_suitable_single_q")

  bind_rows(low_marginal, high_marginal, high_suitable, low_suitable, low_suitable_single_q)
}

make_esg_ranking_by_indicator<-function(quartiles_by_indicator_and_esg_raw, indicator_direction_of_ranking){
  quartiles_by_indicator_and_esg_raw%>%
    left_join(indicator_direction_of_ranking, by="indicator")%>%
    mutate(
      suitable_min = case_when(
        type %in% c("low_marginal", "high_marginal") ~ q25,
        type == "high_suitable" ~ q50,
        type == "low_suitable" ~ min,
        type == "low_suitable_single_q" ~ min
      ),
      suitable_max = case_when(
        type %in% c("low_marginal", "high_marginal") ~ q75,
        type == "high_suitable" ~ max,
        type == "low_suitable" ~ q50,
        type == "low_suitable_single_q" ~ q25
      ),
      marginal_min = case_when(
        type == "low_marginal" ~ min,
        type == "high_marginal" ~ q75,
        type == "high_suitable" ~ q25,
        type == "low_suitable" ~ q50,
        type == "low_suitable_single_q" ~ q25
      ),
      marginal_max = case_when(
        type == "low_marginal" ~ q25,
        type == "high_marginal" ~ max,
        type == "high_suitable" ~ q50,
        type == "low_suitable" ~ q75,
        type == "low_suitable_single_q" ~ q50
      ),
      unsuitable_min = case_when(
        type == "low_marginal" ~ q75,
        type == "high_marginal" ~ min,
        type == "high_suitable" ~ min,
        type == "low_suitable" ~ q75,
        type == "low_suitable_single_q" ~ q50
      ),
      unsuitable_max = case_when(
        type == "low_marginal" ~ max,
        type == "high_marginal" ~ q25,
        type == "high_suitable" ~ q25,
        type == "low_suitable" ~ max,
        type == "low_suitable_single_q" ~ max
      )
    )%>%
    select(ESG, indicator, n:unsuitable_max)
}




