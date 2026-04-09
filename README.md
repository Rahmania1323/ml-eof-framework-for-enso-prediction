# ENSO Long-Lead Prediction Using Hybrid ML–EOF Framework

This repository contains analysis code and outputs for the study:

**“A Hybrid Machine-Learning–EOF Framework for Long-Lead ENSO Prediction Using Ocean–Atmosphere Predictors”**.

---

## 📄 Description

This repository provides scripts and outputs for long-lead prediction of ENSO variability using a hybrid framework that combines *machine learning* and *Empirical Orthogonal Function (EOF)* analysis.

The model integrates multiple ocean–atmosphere predictors, including Niño-3.4 SST anomalies, Southern Oscillation Index (SOI), and Warm Water Volume (WWV), to improve forecast skill across extended lead times.

- **MATLAB scripts** are used for data processing, EOF decomposition, model training, and forecast generation.  
- Model outputs include monthly and seasonal ENSO forecasts, forecast skill evaluation, and uncertainty estimation.

---

## 📁 Structure

- `data/` → external climate indices (downloaded from official sources)  
- `outputs/` → generated figures (Figures 1–6)  
- `scripts/` → MATLAB scripts for analysis and modeling  

---

## 🔗 Data Sources

The climate indices used in this study are publicly available:

- **Niño-3.4 SST anomalies** – NOAA Physical Sciences Laboratory  
  https://psl.noaa.gov/data/timeseries/month/data/nino34.long.anom.data

- **Southern Oscillation Index (SOI)** – NOAA Climate Prediction Center  
  https://www.cpc.ncep.noaa.gov/data/indices/soi

- **Warm Water Volume (WWV)** – NOAA Pacific Marine Environmental Laboratory  
  https://www.pmel.noaa.gov/tao/wwv/data/wwv.dat  

Users are encouraged to download the datasets directly from the official sources.

---

## ▶️ How to Run

### MATLAB

1. Open MATLAB  
2. Navigate to the `scripts/` folder  
3. Run the main script (e.g., `main.m` or equivalent)

The scripts will:
- Load input climate indices  
- Perform EOF analysis  
- Train the hybrid prediction model  
- Generate forecasts and evaluation metrics  
- Save figures to the `outputs/` folder  

---

## 📊 Outputs

The repository includes the following figures:

- **Figure 1** → Climate prediction workflow  
- **Figure 2** → Niño-3.4 forecast vs observation  
- **Figure 3** → Forecast skill (correlation & RMSE)  
- **Figure 4** → Operational ENSO forecast (24 months)  
- **Figure 5** → 9-season ENSO forecast  
- **Figure 6** → Combined monthly & seasonal forecast  

---

## 📌 Notes

- All datasets are externally hosted and not redistributed in this repository.  
- Results may vary slightly depending on preprocessing choices or MATLAB version.  

---
