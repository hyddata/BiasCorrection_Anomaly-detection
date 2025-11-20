CMIP6 Bias Correction & Trend Analysis (MATLAB)

This MATLAB script performs bias correction, model selection, future projection adjustment, and trend/anomaly analysis for CMIP6 precipitation data at a specific latitude–longitude location. The workflow is designed for hydrology, climate impact, and drought/flood risk studies.

Main Features

✅ 1. Import & Pre-processing

Reads precipitation time-series from an Excel file (Bcorrection.xlsx):

Observations (2015–2024)

CMIP6 GCM simulations (historical + SSP scenarios)

Splits the data into:

Calibration: 96 months

Validation: 24 months

✅ 2. Scenario & Model Selection

User selects a CMIP6 scenario from:

ssp126, ssp245, ssp370, ssp585

Script automatically excludes problematic models depending on scenario.

User selects the climate models to use.

✅ 3. Bias Correction Methods

Two bias-correction approaches are included:

A. Quantile Mapping (QM)

Used for all selected CMIP6 models to compare calibration/validation performance.

B. Generalized Additive Model (GAM)

Applied only to the best-performing model.

Model skill is evaluated using:

MAE

RMSE

Pearson correlation

✅ 4. Best Model Detection

The script automatically identifies the best CMIP6 model based on:

RMSE (calibration + validation)

Correlation performance

The best model is then used to correct future CMIP6 data (2025–2050).

✅ 5. Visualization Outputs

The script generates numerous diagnostic plots:

CDF comparison (observed vs. CMIP6 vs. corrected)

Bias-corrected vs. observed (bar plots)

RMSE/MAE histograms

Regression plots (calibration & validation)

Future corrected vs. raw CMIP6 data

Monthly and annual trend lines

Anomaly detection for each decade (2015–2050)

✅ 6. Anomaly & Trend Analysis

Using the full bias-corrected series (2015–2050), the script performs:

Decadal anomaly detection using ±1.5σ threshold

Linear trend estimation for:

Monthly data

Annual averages

Outputs include anomaly tables and trend slopes.



How to Cite

If you use this toolkit, please cite:

**Zare, M. (2025). Climate Data Extraction Toolkit: CMIP6 Time-Series Engine. GitHub Repository. https://github.com/hyddata/BiasCorrection_Anomaly-detection.**
