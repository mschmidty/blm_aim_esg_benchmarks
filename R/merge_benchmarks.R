rank_points<-function(points_to_rank, indicators, esg_ranking_by_indicator){
  points_to_rank%>%
    pivot_longer(cols=all_of(indicators), names_to="indicator", values_to="point_value")%>%
    left_join(esg_ranking_by_indicator, by=c("ESG", "indicator"))%>%
    mutate(ranking = case_when(
      point_value >= suitable_min & point_value < suitable_max ~ "Suitable",
      point_value >= marginal_min & point_value < marginal_max ~ "Marginal",
      point_value >= unsuitable_min & point_value < unsuitable_max ~ "Unsuitable"
    ))%>%
    select(ESG:type, ranking)
}

