extrafont::loadfonts(quiet=TRUE)
ggplot2::theme_set(ggplot2::theme_minimal(base_family="Inter"))

rain_cloud_plot_example_of_point_distribution_ari_warm<-function(comb_esg_tdat_and_lmf_data)(
  comb_esg_tdat_and_lmf_data%>%
        filter(ESG=="Arid Warm - Shallow")%>%
        select(BareSoilCover, TotalFoliarCover, GapCover_25_plus)%>%
        pivot_longer(BareSoilCover:GapCover_25_plus,   names_to="Indicator", values_to="Values")%>%
        ggplot(aes(Indicator, Values, color=Indicator))+
        ggdist::stat_halfeye(aes(fill=Indicator),adjust = .5, width = 0.5, .width = -1, justification = -.3, point_colour = NA) + 
        geom_boxplot(width = .1, outlier.shape = NA) +
        ggdist::stat_dots(side = "left", dotsize = 1.5, justification = 1.1, binwidth = 0.5)+
        coord_flip()+
        labs(
          title="AIM Point Values for Select Indicators Within Arid Warm - Shallow ESG"
        )+
        theme(
          legend.position="none"
        )
)

by_esg_trfo_prop_meets_indicator|>
  filter(total_n>5)|>
  mutate(group=paste0(ESG, " (n=",total_n, ")"))|>
  group_by(ESG)|>
  mutate(indicator=fct_reorder(indicator, Suitable))|>
  ungroup()|>
  pivot_longer(Suitable:Unsuitable, names_to="rank_cat", values_to="prop")|>
  mutate(
    rank_cat=fct_relevel(rank_cat, c("Unsuitable", "Marginal", "Suitable"))
  )|>
  ggplot(aes(ESG, indicator,fill=prop))+
  geom_tile(color="transparent")+
  facet_wrap(~rank_cat)+
  scale_fill_gradientn(colors=met.brewer("OKeeffe1"), trans="reverse")+
  geom_text(aes(label=round(prop, 2)))
  
  
  
