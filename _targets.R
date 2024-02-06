# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)
# library(tarchetypes) # Load other packages as needed. # nolint

# Set target options:
tar_option_set(
  packages = c(
    "tidyverse",
    "trfoaimdata",
    "dplyr",
    "sf",
    "blm_tools",
    "terra",
    "tidyselect",
    "janitor",
    "gt",
    "knitr",
    "ggdist",
    "gghalves",
    "ggforce",
    "extrafont",
    "lubridate"
  ), # packages that your targets need to run
  format = "rds" # default storage format
  # Set other options as needed.
)

# tar_make_clustermq() configuration (okay to leave alone):
options(
  clustermq.scheduler = "multiprocess"
)

# tar_make_future() configuration (okay to leave alone):
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to allow use_targets() to configure tar_make_future() options.

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# source("other_functions.R") # Source other scripts as needed. # nolint

# Replace the target list below with your own:
list(
  # Make Benchmarks
  ## Load all data. See R/load_data.R
  tar_target(indicators, make_indicators()),
  tar_target(esg_rast_file, "data/ESGs/ESGs.tif", format="file"),
  tar_target(tdat_file, "data/sde_up_to_2022.rds", format="file"),
  tar_target(trfo_tdat_clipped, clip_to_trfo_points(tdat_file)),
  tar_target(esg_tdat_data, combine_esg_and_indicator_data(esg_rast_file, tdat_file, indicators, "tdat")),
  tar_target(esg_lmf_data, combine_esg_and_indicator_data(esg_rast_file, tdat_file, indicators, "lmf")),
  tar_target(comb_esg_tdat_and_lmf_data, func_comb_esg_tdat_and_lmf(esg_tdat_data, esg_lmf_data)), 
  tar_target(trfo_esg_tdat_data, trfo_combine_esg_and_terradat(esg_rast_file, tdat_file, indicators)),
  tar_target(benchmarks_by_indicators_file, "output/long_benchmarks_2023.csv", format="file"),
  tar_target(trfo_esg_acres, calc_trfo_esg_cover_acres(esg_rast_file)),

  ## Calc Benchmarks from All available AIM data and ESG layers.
  tar_target(quartiles_by_indicator_and_esg_raw, calc_benchmarks_by_esg_using_tdat_data(comb_esg_tdat_and_lmf_data, indicators)),
  tar_target(indicator_direction_of_ranking, determine_indicator_direction_of_ranking()),
  tar_target(esg_ranking_by_indicator, make_esg_ranking_by_indicator(quartiles_by_indicator_and_esg_raw, indicator_direction_of_ranking)),

  ## Join benchmarks to TRFO data from terradat. See: merge_benchmarks.R
  tar_target(trfo_ranked_points, rank_points(trfo_esg_tdat_data, indicators, esg_ranking_by_indicator)),

  ## complete analysis
  ## make benchmark list
  tar_target(by_esg_trfo_prop_meets_indicator, summarize_trfo_indicators_by_esg(trfo_ranked_points)),
  tar_target(all_trfo_prop_meets_indicator, summarize_trfo_indicators(trfo_ranked_points)),

  ## Output table of indicators for TRFO design for new plan. 
  tar_target(tibble_of_indicators_pasted_from_excel, tibble_of_indicators()),
  tar_target(merged_indicator_rankings, merge_indicator_ranking(esg_ranking_by_indicator, tibble_of_indicators_pasted_from_excel)),
  tar_target(output_all_esg_indicators, output_all_esg_indicators_to_csv(merged_indicator_rankings, "output/final_indicator_rankings/final_indicator_rankings.csv"), format="file"),
  tar_target(output_trfo_important_esg_indicators, output_trfo_important_esg_indicators_to_csv(trfo_esg_acres, merged_indicator_rankings, "output/final_indicator_rankings/final_indicator_rankings_trfo.csv"), format="file"),

  ## Compare my created benchmarks with the benchmarks from the proposed benchmarks from the proposed paper. 
  tar_target(file_from_paper_fractional_cover_any_hit, "data/fractional_cover_any_hit_by_esg_from_paper.csv", format="file"),
  tar_target(from_paper_fractional_cover_any_hit, load_clean_from_paper_fractional_cover_any_hit(file_from_paper_fractional_cover_any_hit)),
  tar_target(comparson_of_paper_indicators_with_mine, join_paper_indicators_to_my_indicators(quartiles_by_indicator_and_esg_raw, from_paper_fractional_cover_any_hit, esg_ranking_by_indicator)),

  ## Reports
  tar_target(example_of_point_distribution_for_arid_warm, rain_cloud_plot_example_of_point_distribution_ari_warm(comb_esg_tdat_and_lmf_data)),
  tar_render(documantation, "Rmd/documentation.Rmd"),

  ## Get GUSG Design Details
  tar_target(trfo_occupied_gusg_habitat, get_trfo_gusg_ch_occupied()),

  ## Get Planning Points with Plotkeys (in load_data.R)
  tar_target(trfo_planning_points_w_plotkeys, get_planning_points_from_tdat(trfo_tdat_clipped)),
  tar_target(output_planning_points_w_plotkeys, output_planning_points_w_plotkeys(trfo_planning_points_w_plotkeys, "output/2018_to_2022_trfo_aim_points_w_plot_keys.shp"), format="file")
)

