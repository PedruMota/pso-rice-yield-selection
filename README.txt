# Optimization of Feature Selection for Rice Yield Prediction using PSO 🌾🧬

![R](https://img.shields.io/badge/Language-R-blue)
![Domain](https://img.shields.io/badge/Domain-Agritech-green)
![Status](https://img.shields.io/badge/Status-Completed-success)

## 📋 About the Project

Predicting crop productivity (Grain Yield) is a complex challenge in Agronomy due to the **high dimensionality** and **multicollinearity** of climatic and phenotypic variables. Traditional models often suffer from overfitting when fed with excessive predictors, making them hard to interpret and unreliable for future harvest cycles.

This project implements a **Computational Statistics** approach to select the optimal subset of predictor variables for Upland Rice Yield.

We utilized **Particle Swarm Optimization (PSO)**, a meta-heuristic algorithm, to navigate the feature space, minimizing the model's error while penalizing model complexity.

## 💼 Business Context

In the Agribusiness sector, data collection is expensive. Identifying which specific indicators (e.g., Accumulated Rainfall vs. Flowering Days vs. Plant Height) truly impact yield allows for:
1.  **Cost Reduction:** Focusing field data collection only on what matters.
2.  **Precision:** Building more robust models that generalize better to new environments.
3.  **Explainability:** Providing agronomists with a clear list of yield-driving factors.

## 🛠️ Tech Stack

* **Language:** R
* **Optimization:** `pso` (Particle Swarm Optimization)
* **Modeling:** `lme4`, `glmmTMB`, `lm`
* **Data Manipulation:** `tidyverse`
* **Evaluation Metric:** MAE (Mean Absolute Error)

## ⚙️ How it Works

The feature selection problem was modeled as a binary search task where each "particle" in the PSO swarm represents a subset of variables.

1.  **Search Space:** A binary vector where 1 = Variable Included, 0 = Variable Excluded.
2.  **Fitness Function (Cost):** $Cost = MAE_{train} + (\lambda \times N_{vars})$
    * The algorithm seeks the lowest error but is "taxed" for every additional variable it selects.
3.  **Result:** Convergence towards a **parsimonious model** (fewer variables, high accuracy).

## 🚀 How to Run

*Note: Due to confidentiality agreements, the original dataset is not included. However, this repository includes a **synthetic data generator** that simulates the statistical properties of the original data for demonstration purposes.*

1. Clone the repository:
   ```bash
   git clone [https://github.com/your-username/rice-yield-pso.git](https://github.com/your-username/rice-yield-pso.git)

2. Open rice-yield-optimization.Rproj in RStudio.

3. Run the main.R script.

The script will automatically detect the absence of real data and generate the synthetic dataset.

📊 Expected Results
The algorithm successfully reduces dimensionality from over 60 predictors to a focused subset (typically < 10), keeping the predictive error (MAE) controlled while drastically improving model interpretability.

Developed by [Your Name] - Statistics Student | Focus on Data Science & Agro