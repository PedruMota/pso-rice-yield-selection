process_data <- function(raw_data) {

  data1 <- raw_data %>% 
    filter(complete.cases(.)) %>% 
    mutate(
      LOD = as.factor(LOD),
      LBL = as.factor(LBL),
      PBL = as.factor(PBL),
      BSP = as.factor(BSP),
      LSC = as.factor(LSC),
      GDS = as.factor(GDS)
    ) %>% 
    mutate(
      DECADE = case_when(
        YEAR >= 1980 & YEAR <= 1989 ~ "1980s",
        YEAR >= 1990 & YEAR <= 1999 ~ "1990s",
        YEAR >= 2000 & YEAR <= 2009 ~ "2000s",
        YEAR >= 2010 & YEAR <= 2019 ~ "2010s",
        YEAR >= 2020 ~ "2020s",
        TRUE ~ "Before 1980s"
      ),
      DECADE = as.factor(DECADE)
    ) %>% 
    relocate(DECADE, .after = YEAR) %>% 
    dplyr::select(-SYST, -YEAR)
  
  return(data1)
}
