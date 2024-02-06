load_clean_from_paper_fractional_cover_any_hit<-function(file){
  paper_indicators<-read_csv(file, show_col_types = FALSE)%>%
    janitor::clean_names()%>%
    mutate(soil_geom_unit_s = case_when(
      soil_geom_unit_s=="Sandy & Loamy Uplands" ~ "Sandy Uplands, Loamy Uplands",
      soil_geom_unit_s=="Shallow & Deep Rocky" ~ "Shallow, Deep Rocky",
      soil_geom_unit_s=="Sandy Bottoms & Bottoms" ~ "Sandy Bottoms, Bottoms",
      soil_geom_unit_s=="Finer and Clay Uplands" ~ "Finer Uplands, Clay Uplands",
      soil_geom_unit_s=="Saline Bottoms & Bottoms" ~ "Saline Bottoms, Bottoms",
      soil_geom_unit_s=="Sandy Bottoms" ~ "Sandy Bottoms",
      soil_geom_unit_s=="Saline, Sandy, Loamy, & Finer Uplands" ~ "Saline Uplands, Sandy Uplands, Loamy Uplands, Finer Uplands",
      TRUE~soil_geom_unit_s
    ))%>%
    mutate(esg=paste(climate, soil_geom_unit_s, sep=" - "))%>%
    select(esg, big_sage:total_foliar)%>%
    mutate(
      perennial_grass = c3_perennial_grass+c4_perennial_grass, 
      sage = mountain_sage+basin_sage+big_sage
    )%>%
    pivot_longer(big_sage:sage)

    crosswalk<-tibble(
      paper_indicator = paper_indicators%>%
        count(name)%>%
        pull(name),
      indicator = c(NA, NA, NA, NA, NA, NA, "AH_NonNoxPerenForbCover", NA, NA, NA, NA, NA, "AH_NonNoxPerenGrassCover", NA, NA, NA, "AH_SagebrushCover", NA, NA, NA, "TotalFoliarCover", "AH_NonNoxTreeCover" )
    )
    paper_indicators%>%
      left_join(crosswalk, by=c("name" = "paper_indicator"))%>%
      mutate(indicator = case_when(
        name == "shrub" ~ "AH_NonNoxShrubCover",
        TRUE ~ indicator
      ))
}

join_paper_indicators_to_my_indicators<-function(quartiles_by_indicator_and_esg_raw, from_paper_fractional_cover_any_hit, esg_ranking_by_indicator){
  quartiles_by_indicator_and_esg_raw%>%
    left_join(from_paper_fractional_cover_any_hit, by=c("ESG" = "esg", "indicator"="indicator"))%>%
    filter(!is.na(name))%>%
    mutate(indicator_diff = q50-value)%>%
    left_join(esg_ranking_by_indicator, by=c("ESG", "indicator"))%>%
    mutate(paper_indicator_ranking = case_when(
      value >= suitable_min & value < suitable_max ~ "Suitable",
      value >= marginal_min & value < marginal_max ~ "Marginal",
      value >= unsuitable_min & value < unsuitable_max ~ "Unsuitable"
    ))%>%
    select(ESG:indicator_diff, paper_indicator_ranking)
}



