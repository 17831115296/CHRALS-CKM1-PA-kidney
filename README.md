
# Physical Activity Patterns and Kidney Disease Risk in CKM Stage 1

## Overview
This repository contains analysis code and derived data for the study on physical activity patterns and kidney disease risk among middle-aged and elderly adults with stage 1 cardiovascular-kidney-metabolic syndrome using CHARLS dataset.

## Data Source
- Raw individual-level data originate from the publicly available China Health and Retirement Longitudinal Study (CHARLS) database. Access requires approval at [https://charls.pku.edu.cn/en](https://charls.pku.edu.cn/en).
- This repository contains only derived summary statistics, processed data and analysis code.

## Study Cohort
The investigation employed the 2015 CHARLS national survey data as baseline, with follow-up from 2018 and 2020 surveys. The final analytical sample comprised 2,569 participants after applying inclusion/exclusion criteria based on CKM stage 1 definition and follow-up availability.

## Repository Contents
- **Data Cleaning Code.R**: Script for data extraction, preprocessing, cohort definition, and variable transformation
- **Statistical Analysis Code.R**: Code for latent class growth modeling (LCGM), restricted cubic spline analysis, generalized linear models, and subgroup analyses
- **Processed Data Extraction.xlsx**: Summary data tables and derived statistics suitable for public sharing

## Analysis Methods
Data analysis was performed using R software (version 4.4.3) with the following key approaches:

### Data Preprocessing
- Multiple imputation techniques (mice package with random forest method) to address missing data
- Longitudinal data transformation for trajectory analysis

### Trajectory Analysis
- Latent Class Growth Modeling (LCGM) using mixed-effects models on MET data from three time points
- Model evaluation using AIC, BIC, and Average Posterior Probability (AvePP)
- Two distinct physical activity patterns identified: 
  - Low-level Continuously Declining Physical Activity pattern (LCDPA)
  - High-level Parabolic Physical Activity pattern (HPPA)

### Association Analysis
- Restricted Cubic Spline (RCS) analysis to examine nonlinear relationships between MET values and CKD risk
- Threshold analysis using segmented regression to identify critical MET thresholds
- Generalized linear models with progressive adjustment levels:
  - Model 1: Unadjusted
  - Model 2: Adjusted for demographic factors
  - Model 3: Fully adjusted model including clinical parameters
- Subgroup analyses across demographic and clinical characteristics

## Key Findings
- Two distinct physical activity trajectory patterns identified among middle-aged and elderly adults with CKM stage 1
- High-level Parabolic Physical Activity pattern associated with significantly reduced CKD incidence risk (OR=0.18, 95%CI=0.13-0.24, P<0.001)
- Nonlinear relationship between physical activity levels and CKD risk with significant threshold effects
- Consistent protective effects of HPPA against CKD risk across diverse population segments

## Reproducibility
All R code is documented with comments for reproducibility. For execution:
1. Obtain CHARLS data from the official website with proper approvals
2. Run Data Cleaning Code.R to process the raw data
3. Run Statistical Analysis Code.R to reproduce analyses and figures

## Citation
If you use these materials, please cite:
```
[Author names], "Association between novel physical activity patterns and risk of kidney disease among middle-aged and elderly adults with stage 1 cardiovascular-kidney-metabolic syndrome: A nationwide prospective cohort study," [Journal], 2023. GitHub: https://github.com/17831115296/CHARLS-CKM1-PA-kidney
```

## License
This project is licensed under CC-BY 4.0
