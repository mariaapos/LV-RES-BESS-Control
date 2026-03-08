# Control Strategies for Renewable Energy Sources and Battery Systems

## Project Overview

This project implements a co-simulation framework using **MATLAB** and **OpenDSS** to evaluate voltage regulation strategies in a Low-Voltage (LV) distribution network. The simulation addresses technical challenges caused by high penetrations of Photovoltaic (PV) systems, such as overvoltage and undervoltage violations.

The project models a realistic European LV network and compares four distinct inverter control strategies, including the coordination of Battery Energy Storage Systems (BESS).

## Key Features

* **Time-Series Simulation:** Runs 24-hour QSTS (Quasi-Static Time Series) simulations at 1-minute intervals.
* **Co-Simulation:** Leverages MATLAB for control logic and OpenDSS for power flow solving via the COM interface.
* **Grid Modeling:** Detailed 3-phase unbalanced European LV network (36 buses, 11 loads, 7 PVs, 4 BESS).
* **Control Strategies:**
    * **No Control:** Baseline PV operation.
    * **Q-V Droop Control:** Reactive power modulation based on voltage.
    * **P-V Droop Control:** Active power curtailment.
    * **Power Factor (PF) Control:** Dynamic $cos(\phi)$ adjustment.
    * **BESS Coordination:** Constant Power (CP) charging/discharging logic combined with PV PF control.
* **Analysis Tools:** Automated detection of voltage violations and SoC tracking.

## Prerequisites

To run this simulation, you need:

1.  **MATLAB** (R2023b or compatible).
2.  **OpenDSS** (Open Distribution System Simulator).
    * *Download:* [SourceForge - OpenDSS](https://sourceforge.net/projects/electricdss/)
    * *Note:* Ensure the OpenDSS COM server is registered.
3.  **Data Files:** The simulation requires the following `.mat` files in the root directory:
    * `Interpolated_1min.mat` 
    * `Names.mat` 
    * `Saved_values.mat`
