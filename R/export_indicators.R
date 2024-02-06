
## Copied from excel, may want to consider doing this another way. 
tibble_of_indicators<-function(){tibble::tribble(
                                            ~AIM.Indicator,               ~terradat_name,                                                                                                                                                   ~`Land.Health.Standard.and/or.Management.Question`,
                                         "Bare ground (%)",              "BareSoilCover",                                                                                                                                     "LHA Standard 1:  Bare ground does not exceed adequate amounts.",
                                        "Foliar cover (%)",           "TotalFoliarCover",                                                                                                                               "LHA Standard 1: and plant foliar cover is adequate to protect soils.",
                   "Proportion of canopy gaps (%) > 25 cm",           "GapCover_25_plus",                                                                                                                                              "LHA Standard 1: are canopy and ground cover adequate.",
          "Proportion of canopy gaps (%) 101 cm to 200 cm",           "GapCover_101_200",                                                                                                                                             "LHA Standard 1:  are canopy and ground cover adequate.",
                    "Proportion of anopy gaps (%) > 200cm",          "GapCover_200_plus",                                                                                                                                              "LHA Standard 1: are canopy and ground cover adequate.",
    "Between Canopy Herbaceous and Woody Litter Cover (%)", "FH_WoodyAndHerbLitterCover",                                                                                                      "LHA Standard 1: Is litter accumulating in place and not sorted by normal overland water flow?",
                   "Non-invasive Perennial Forb Cover (%)",    "AH_NonNoxPerenForbCover", "LHA Standard 3: Are native plant communities spatially distributed across the landscape with a composition and frequency of species suitable to ensure reproductive capability and sustainability?",
                              "Perennial Forb Height (cm)",          "Hgt_PerenForb_Avg",                                                                                                                                                                                                   NA,
                  "Non-invasive Perennial Grass Cover (%)",   "AH_NonNoxPerenGrassCover", "LHA Standard 3: Are native plant communities spatially distributed across the landscape with a composition and frequency of species suitable to ensure reproductive capability and sustainability?",
                "Non-invasive Perennial Grass Height (cm)",   "Hgt_NonNoxPerenGrass_Avg", "LHA Standard 3: Are native plant communities spatially distributed across the landscape with a composition and frequency of species suitable to ensure reproductive capability and sustainability?",
                             "Non-invasive Tree Cover (%)",         "AH_NonNoxTreeCover", "LHA Standard 3: Are native plant communities spatially distributed across the landscape with a composition and frequency of species suitable to ensure reproductive capability and sustainability?",
                                  "Non-invasive Shrub (%)",        "AH_NonNoxShrubCover", "LHA Standard 3: Are native plant communities spatially distributed across the landscape with a composition and frequency of species suitable to ensure reproductive capability and sustainability?",                             
                         "Invasive Annual Grass Cover (%)",        "AH_NoxAnnGrassCover",                                                                                                  "LHA Standard 3: Are noxious weeds and undesirable species minimal in the overall plant community?",
                                "Invasive Plant Cover (%)",                "AH_NoxCover",                                                                                                  "LHA Standard 3: Are noxious weeds and undesirable species minimal in the overall plant community?",
                    "Number of Invasive Plant Species (n)",            "NumSpp_NoxPlant",                                                                                                  "LHA Standard 3: Are noxious weeds and undesirable species minimal in the overall plant community?",
                                     "Sagebrush Cover (%)",          "AH_SagebrushCover",                                                                                                  "LHA Standard 3: Are noxious weeds and undesirable species minimal in the overall plant community?",
                           "Average Sagebrush Height (cm)",          "Hgt_Sagebrush_Avg",                                                                              "LHA Standard 3: Are plants present in mixed age classes sufficient to sustain recruitment and mortality fluctuations?",
       "Dead Sagebrush Cover (% of total sagebrush cover)",         "pct_sagebrush_dead",                                                                              "LHA Standard 3: Are plants present in mixed age classes sufficient to sustain recruitment and mortality fluctuations?",
                 "Protected Surface Soil Stability Rating",    "SoilStability_Protected",                                        "LHA Standard 1: Do upland soils exhibit infiltration and permeability rates that are appropriate to soil type, climate, landform, and geological processes?",
               "Unprotected Surface Soil Stability Rating",  "SoilStability_Unprotected",                                        "LHA Standard 1: Do upland soils exhibit infiltration and permeability rates that are appropriate to soil type, climate, landform, and geological processes?",
                        "Browse (NEED TO FIGURE THIS OUT)",                           NA,                                                                                                                                                                                                   NA,
                                         "Sagebrush Shape",                           NA,                                                                              "LHA Standard 3: Are plants present in mixed age classes sufficient to sustain recruitment and mortality fluctuations?"
    )
}

merge_indicator_ranking<-function(esg_ranking_by_indicator, tibble_of_indicators){
  concat_rankings_and_transform<-esg_ranking_by_indicator%>%
    mutate(mergeable_indicator = paste0(
      "Suitable: >= ", round(suitable_min, 1),  " & < ", round(suitable_max, 1),
      ";  Marginal: >= ", round(marginal_min, 1),  " & < ", round(marginal_max,1),
      ";  Unsuitable: >= ", round(unsuitable_min, 1),  " & < ", round(unsuitable_max, 1)
    ))%>%
    mutate(mergeable_indicator = case_when(
      is.na(suitable_min) ~ "Not enough data to calculate indicator.",
      is.na(suitable_max) ~ "Not enough data to calculate indicator.",
      is.na(unsuitable_min) ~ "Not enough data to calculate indicator.",
      is.na(unsuitable_min) ~ "Not enough data to calculate indicator.",
      is.na(marginal_min) ~ "Not enough data to calculate indicator.",
      is.na(marginal_min) ~ "Not enough data to calculate indicator.",
      TRUE ~ mergeable_indicator
    ))%>%
    select(ESG, indicator, mergeable_indicator)%>%
    pivot_wider(names_from=ESG, values_from=mergeable_indicator)

    tibble_of_indicators%>%
      left_join(concat_rankings_and_transform, by=c("terradat_name" = "indicator"))
}

output_all_esg_indicators_to_csv<-function(merged_indicator_rankings, location){
  write_csv(merged_indicator_rankings, location)
  location
}

output_trfo_important_esg_indicators_to_csv<-function(trfo_esg_acres, merged_indicator_rankings, location){
  important_esgs<-trfo_esg_acres%>%
    filter(approx_acres>3000 & esg != "Outcrops" & esg != "Riparian")%>%
    pull(esg)

    merged_indicator_rankings%>%
      select(AIM.Indicator:"Land.Health.Standard.and/or.Management.Question", all_of(important_esgs))%>%
      write_csv(location)
    location
}