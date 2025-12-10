# R/generate_synthetic.R

generate_synthetic_data <- function(n = 600, output_path = "data/train_data.csv") {
  
  # 1. Geographic Consistency (Hierarchy: ST -> LOC)
  # We create a lookup table to ensure a City (LOC) always belongs to the same State (ST)
  locations_lookup <- data.frame(
    LOC = paste0("LOC", 1:10),
    ST  = c(rep("GO", 3), rep("MT", 3), rep("RO", 2), rep("TO", 2)) 
    # LOC1-3 are GO, LOC4-6 are MT, etc.
  )
  
  # Generate base indices
  loc_indices <- sample(1:10, n, replace = TRUE)
  selected_locs <- locations_lookup[loc_indices, ]
  
  df <- data.frame(
    YEAR = sample(1980:2022, n, replace = TRUE),
    ST   = selected_locs$ST,
    LOC  = selected_locs$LOC,
    GEN  = sample(paste0("GEN", 1:25), n, replace = TRUE), # 25 Genotypes
    
    # Phenotypic variables
    # H2 removed from predictors as requested
    H2  = runif(n, 0.2, 0.9), # Heritability (just as noise/metadata)
    PHT = runif(n, 70, 140),  # Plant Height (cm)
    DTF = runif(n, 60, 110),  # Days to Flowering
    
    # Categorical Scores (simulated as integers)
    LOD = sample(1:9, n, replace = TRUE),
    LBL = sample(1:7, n, replace = TRUE),
    
    # Climatic variables (Crucial for the non-linear relationship)
    PRECTOT_ACC = runif(n, 400, 1200), # Accumulated Precipitation (mm)
    T2M_MEAN    = runif(n, 22, 28),    # Mean Temperature (C)
    RH2M_MEAN   = runif(n, 60, 90),    # Relative Humidity
    SOLAR_RAD   = runif(n, 15, 25)     # Solar Radiation
  )
  
  # Fill remaining columns with noise to reach ~60 vars (Simulating high dimensionality)
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
  gen_effects <- rnorm(25, mean = 0, sd = 300)
  names(gen_effects) <- paste0("GEN", 1:25)
  
  df$GY <- 2000 + 
    (15 * df$PHT) +                         # Linear: Taller plants -> more yield
    (-2 * (df$DTF - 85)^2) +                # Non-linear: Bell curve peaking at 85 days
    (0.05 * df$PRECTOT_ACC * df$T2M_MEAN) + # Interaction: Rain * Temp
    gen_effects[df$GEN] +                   # Random Effect (lmer will catch this)
    rnorm(n, mean = 0, sd = 400)            # Residual Error
  
  # Ensure realistic positive values
  df$GY <- ifelse(df$GY < 500, 500, df$GY)
  
  # Save
  if(!dir.exists(dirname(output_path))) dir.create(dirname(output_path))
  write.csv(df, output_path, row.names = FALSE)
  message("Synthetic data generated with logical constraints at: ", output_path)
}