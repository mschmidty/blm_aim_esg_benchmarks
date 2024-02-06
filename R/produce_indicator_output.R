summarize_trfo_indicators_by_esg<-function(trfo_tdat_with_indicators){
  trfo_tdat_with_indicators%>%
    filter(!is.na(ranking))%>%
    count(ESG, indicator, ranking)%>%
    group_by(ESG, indicator)%>%
    mutate(
      prop = n/sum(n),
      total_n=sum(n)
    )%>%
    ungroup()%>%
    arrange(desc(total_n))%>%
    pivot_wider(-n,names_from = ranking, values_from = prop)%>%
    select(ESG, indicator, total_n, Suitable, Marginal, Unsuitable)
}

summarize_trfo_indicators<-function(trfo_tdat_with_indicators){
  trfo_tdat_with_indicators%>%
    filter(!is.na(ranking))%>%
    count(indicator, ranking)%>%
    group_by(indicator)%>%
    mutate(
      prop = n/sum(n),
      total_n=sum(n)
    )%>%
    ungroup()%>%
    pivot_wider( -n,names_from = ranking, values_from = prop )%>%
    select(indicator, total_n, Suitable, Marginal, Unsuitable)
}



