# 🌾 Rice Yield Feature Optimization: A Swarm Intelligence Approach

![R](https://img.shields.io/badge/Language-R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Domain](https://img.shields.io/badge/Domain-AgriTech-4CAF50?style=for-the-badge&logo=leaf&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active-blue?style=for-the-badge)

> **An automated feature selection framework using Particle Swarm Optimization (PSO) to identify key climatic and phenotypic drivers of Upland Rice productivity.**

---

## 📋 Executive Summary

Predicting crop yield is a high-dimensional problem. Agronomists and Data Scientists often face datasets with hundreds of variables (climatic sensors, soil samples, genetic markers), leading to **multicollinearity**, **overfitting**, and **high data collection costs**.

This project implements a **meta-heuristic wrapper** around Machine Learning models. Instead of using traditional Stepwise methods, I deployed a **Particle Swarm Optimization (PSO)** algorithm to navigate the complex search space and find the optimal subset of variables that minimizes error while maximizing model simplicity.

**Key Achievement:** The algorithm successfully reduces 50+ noisy predictors to a robust subset of <10 key drivers, maintaining high predictive accuracy on unseen data.

---

## ⚙️ Engineering & Methodology

This isn't just a script; it's a robust selection pipeline designed with production-level best practices.

### 1. 🧠 Warm Start Strategy (Heuristic Initialization)
Instead of starting the swarm at completely random positions, the algorithm uses **Domain Knowledge Injection**.
* It calculates the Pearson correlation of all features against the target.
* It initializes a percentage of the particles (the "Leaders") with the top-correlated variables already selected.
* **Impact:** Drastically reduces convergence time and prevents the swarm from getting stuck in poor local optima early on.

### 2. ⚖️ Dynamic Complexity Penalty (Regularization)
To prevent the selection of "lucky noise" (spurious correlations), the Fitness Function applies an economic sanction on the model.
* **The Math:** $Penalty = N_{vars} \times (\sigma_{y} \times \lambda)$
* The penalty is calculated dynamically based on the Standard Deviation ($\sigma$) of the target variable.
* **Impact:** A variable is only selected if its contribution to reducing the MAE is significantly higher than the "tax" it costs to keep it.

### 3. 🛡️ Robust Validation (5-Fold CV)
To ensure the selected variables are stable and not results of overfitting a specific data split:
* The fitness function runs a **5-Fold Cross-Validation** for every single particle in every iteration.
* This ensures that selected features perform consistently across different data subsets.

---

## 🛠️ Tech Stack & Models

The framework is **Model Agnostic**, allowing the user to switch the evaluation engine based on the problem type:

| Model Engine | Use Case | Pros |
| :--- | :--- | :--- |
| **Linear Model (LM)** | Feature Inference | High interpretability, extremely fast. Ideal for understanding relationships. |
| **Random Forest (RF)** | Predictive Performance | Captures non-linearities and complex interactions (e.g., *Rain* $\times$ *Temp*). |

**Libraries:** `pso` (Optimization), `ranger` (Fast Random Forest), `caret` (Validation), `tidyverse` (Data Engineering).

---

## 🚀 How to Run

This project includes a **Synthetic Data Generator** that simulates realistic agronomic conditions (Phenotypes, Climate, and Soil interactions) while preserving data privacy.

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/your-username/pso-rice-yield-selection.git](https://github.com/your-username/pso-rice-yield-selection.git)
   ```
   
2. **Open the Project**: Double-click *rice-yield-optimization.Rproj* to open RStudio with the correct environment context.

3. **Run the Pipeline**: Open main.R and execute.
  *Note*: The script will automatically check for data. If missing, it triggers R/generate_synthetic.R to create a fresh dataset.
  

## 📊 Project Structure


```text
rice-yield-optimization/
├── data/                     # Generated synthetic datasets (excluded from git)
├── output/                   # Logs, saved models (.rds), and PSO results
├── R/                        # Modularized functions
│   ├── generate_synthetic.R  # Simulates agronomic data logic
│   ├── model_utils.R         # Wrapper for LM/RF training & CV
│   └── process_data.R        # Data cleaning pipeline
├── main.R                    # Orchestrator script (Configuration & Execution)
├── .gitignore                # Git configuration
└── README.md                 # Documentation
```

## 🔮 Roadmap & Contributions

This project is a proof-of-concept for my portfolio, and there is significant room for improvement. I am actively studying Data Engineering and ML to enhance it.

**Future Improvements:**

- [ ] **XGBoost Integration:** Implement Gradient Boosting to handle residuals better than RF.
- [ ] **Hyperparameter Tuning:** Add a nested optimization loop to tune `mtry` (RF) or `lambda` (LM) simultaneously with feature selection.
- [ ] **Dockerization:** Containerize the environment to ensure full reproducibility across OSs.
- [ ] **MLOps Logging:** Integrate `mlflow` to track experiments and metrics visualization.

Feedback is welcome! If you have suggestions on code optimization or statistical rigor, please open an Issue or reach out on LinkedIn.

Developed by Pedro Mota - Statistics Student | Focus on Data Science & Agribusiness 🚜