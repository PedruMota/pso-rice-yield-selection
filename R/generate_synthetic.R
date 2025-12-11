# R/generate_synthetic.R

generate_synthetic_data <- function(n = 600, output_path = "data/train_data.csv") {
  
  # Geographic Consistency (Hierarchy: ST -> LOC)
  locations_lookup <- data.frame(
    LOC = paste0("LOC", 1:10),
    ST  = c(rep("GO", 3), rep("MT", 3), rep("RO", 2), rep("TO", 2)))
  
  # Generate base indices
  loc_indices <- sample(1:10, n, replace = TRUE)
  selected_locs <- locations_lookup[loc_indices, ]
  
  # Generating Base Climatic Data (Temperature Core)
  # We generate Mean first, then derive Min/Max to ensure physical consistency
  base_t2m_mean <- runif(n, 22, 28)
  
  df <- data.frame(
    YEAR = sample(1980:2022, n, replace = TRUE),
    SYST = sample(c("S1", "S2"), n, replace = TRUE),
    ST   = selected_locs$ST,
    LOC  = selected_locs$LOC,
    GEN  = sample(paste0("GEN", 1:25), n, replace = TRUE),
    DTF = runif(n, 60, 110),  # Days to Flowering
    
    # Phenotypic variables
    PHT = runif(n, 70, 140),
    LOD = sample(1:9, n, replace = TRUE),
    LBL = sample(1:7, n, replace = TRUE),
    PBL = sample(1:9, n, replace = TRUE),
    BSP = sample(1:9, n, replace = TRUE),
    LSC = sample(1:8, n, replace = TRUE),
    GDS = sample(1:8, n, replace = TRUE),
    
    # Climatic variables
    # Temperature Family (Highly Collinear - Hard for models!)
    T2M_MEAN = base_t2m_mean, # Mean Temperature (C)
    T2M_MAX  = base_t2m_mean + runif(n, 5, 12), # Max is higher than mean
    T2M_MIN  = base_t2m_mean - runif(n, 5, 10), # Min is lower than mean
    
    # Humidity & Water
    PRECTOT_ACC = runif(n, 400, 1200), # Accumulated Precipitation (mm)
    RH2M_MEAN = runif(n, 60, 90), # Relative Humidity
    T2MDEW    = base_t2m_mean - runif(n, 2, 5), # Dew point related to temp
    
    # Energy & Wind
    SOLAR_RAD = runif(n, 15, 25),    # Solar Radiation (MJ/m2)
    WS2M      = runif(n, 1, 6)       # Wind Speed (m/s)
  )
  
  # Fill remaining columns with noise (Simulating high dimensionality)
  noise_cols <- paste0("NOISE_", 1:40)
  for(col in noise_cols) {
    df[[col]] <- runif(n, 0, 10)
  }
  
  # 2. Generating GY (Grain Yield) with Non-Linear Logic
  # Formula: 
  # Base Yield 
  # + Linear Effect of Plant Height (PHT)
  # + Quadratic Effect of DTF (Optimal flowering time ~85 days)
  # + Interaction: Rain is only beneficial if Temp is within optimal range
  
  # Random effect for Genotype (Intercept variation)
  gen_effects <- rnorm(25, mean = 0, sd = 150)
  names(gen_effects) <- paste0("GEN", 1:25)
  
  interaction_term <- (df$PRECTOT_ACC * df$SOLAR_RAD) / 25 
  
  df$GY <- 1500 + 
    (18 * df$PHT) +
    (1.5 * df$PRECTOT_ACC) +
    (1.2 * (df$PRECTOT_ACC * df$SOLAR_RAD) / 25) +  
    (-80 * (df$T2M_MAX - 28)) +
    gen_effects[df$GEN] +                   
    rnorm(n, mean = 0, sd = 300)
  
  # Ensure realistic positive values
  df$GY <- ifelse(df$GY < 500, 500, df$GY)
  
  # Save
  if(!dir.exists(dirname(output_path))) dir.create(dirname(output_path))
  write.csv(df, output_path, row.names = FALSE)
  message("Synthetic data generated with logical constraints at: ", output_path)
}