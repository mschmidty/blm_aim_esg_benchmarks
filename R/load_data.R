clip_to_trfo_points<-function(tdat_file){
  all_terradat<-readRDS(tdat_file)
  tdat_only<-all_terradat$tdat

  tdat_only%>%
    st_transform(st_crs(trfo_b))%>%
    st_intersection(trfo_b)%>%
    mutate(
      date=as.Date(DateVisited),
      purpose=case_when(
        !is.na(Purpose)~Purpose,
        str_detect(PlotID,  "^GRSGInt")~"GUSG",
        year(date)<2018~"Random",
        TRUE ~ "Planning"
      )
    )
}

combine_esg_and_indicator_data<-function(esg_path, indicator_data_path, indicators, dataset){
  esg<-rast(esg_path)
  activeCat(esg)<-"ESG"

  all_terradat<-readRDS(indicator_data_path)
  indicator_data<-all_terradat[[dataset]]

  indicator_data_cl<-indicator_data%>%
    sf::st_transform(crs(esg))

  final_data<-terra::extract(esg, as(indicator_data_cl, "SpatVector"))%>%
    dplyr::select(ESG)%>%
    cbind(indicator_data_cl)%>%
    as_tibble()%>%
    filter(!is.na(ESG))%>%
    mutate(
      pct_sagebrush_dead=((AH_SagebrushCover-AH_SagebrushCover_Live)/AH_SagebrushCover)*100,
      FH_WoodyAndHerbLitterCover = FH_WoodyLitterCover+FH_HerbLitterCover
    )%>%
    select(ESG, PlotID, all_of(indicators))

    return(final_data)
}

func_comb_esg_tdat_and_lmf<-function(esg_tdat_data, esg_lmf_data){
  bind_rows(esg_tdat_data, esg_lmf_data)
}

trfo_combine_esg_and_terradat<-function(esg_path, tdat_path, indicators){
  esg<-rast(esg_path)
  activeCat(esg)<-"ESG"

  all_terradat<-readRDS(tdat_path)
  tdat<-all_terradat$tdat

  tdat_cl<-tdat%>%
  st_transform(st_crs(trfo_b))%>%
    st_intersection(trfo_b)%>%
    sf::st_transform(crs(esg))

  final_data<-terra::extract(esg, as(tdat_cl, "SpatVector"))%>%
    dplyr::select(ESG)%>%
    cbind(tdat_cl)%>%
    as_tibble()%>%
    filter(!is.na(ESG))%>%
    mutate(
      pct_sagebrush_dead=((AH_SagebrushCover-AH_SagebrushCover_Live)/AH_SagebrushCover)*100,
      FH_WoodyAndHerbLitterCover = FH_WoodyLitterCover+FH_HerbLitterCover
    )%>%
    select(ESG, PlotID, all_of(indicators))

    return(final_data)
}

calc_trfo_esg_cover_acres<-function(esg_path){
  esg<-rast(esg_path)
  activeCat(esg)<-"ESG"

  trfo_blm_tr<-trfo_blm%>%
    st_collection_extract("POLYGON")%>%
    st_transform(crs(esg))
  
  trfo_cropped_esg_raster<-esg%>%
    crop(trfo_blm_tr)%>%
    mask(as(trfo_blm_tr, "SpatVector"))
  
  freq(trfo_cropped_esg_raster)%>%
    as_tibble()%>%
    mutate(approx_acres = round((count*30*30)*0.000247105))%>%
    select(value, approx_acres)%>%
    arrange(desc(approx_acres))%>%
    filter(!is.na(value))%>%
    rename(esg=value)
}

benchmarks_by_indicators<-function(file_path){
  ## Should probably make the creation of this part of this workflow.
  read_csv(file_path)%>%
    mutate(directional_indicator = ifelse(is.na(directional_indicator), "sd", directional_indicator))
}

make_indicators<-function(){
  calc_variables=c(
      "BareSoilCover",
      "TotalFoliarCover", 
      "GapCover_25_plus",
      "GapCover_101_200",
      "GapCover_200_plus",
      "AH_NonNoxPerenForbCover",
      "Hgt_PerenForb_Avg",
      "AH_NonNoxPerenGrassCover",
      "Hgt_NonNoxPerenGrass_Avg",
      "AH_NonNoxShrubCover",
      "AH_NonNoxTreeCover",
      "AH_NoxAnnGrassCover",
      "AH_NoxCover",
      "NumSpp_NoxPlant",
      "AH_SagebrushCover",
      "Hgt_Sagebrush_Avg",
      "pct_sagebrush_dead",
      "SoilStability_Protected",
      "SoilStability_Unprotected",
      "FH_WoodyAndHerbLitterCover"
      )
  return(calc_variables)
}

get_planning_points_from_tdat<-function(tdat_clipped_to_trfo){
  tdat_clipped_to_trfo%>%
    filter(purpose=="Planning")%>%
    select(PrimaryKey:PlotID, DateVisited)
}

output_planning_points_w_plotkeys<-function(x, output_dir){
  st_write(x, output_dir, append=FALSE)
  output_dir
}

