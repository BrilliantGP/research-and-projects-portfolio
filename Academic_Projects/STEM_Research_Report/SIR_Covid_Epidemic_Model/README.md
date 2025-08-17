# Mathematical Modelling, Simulation, and Optimal Vaccination Rate for COVID-19 in Jakarta

This report applies compartmental epidemic modelling to the COVID-19 outbreak in Jakarta, combining **SIR/SEIRDV dynamics**, **parameter estimation from local data**, **R₀ analysis**, and **scenario testing for vaccination rates and site placement**. The work balances mathematical rigour with policy-oriented insights for public-health decision making.

# External Links
[Read on Academia.edu – Mathematical Modelling of Epidemic Spread and Control Strategies](https://www.academia.edu/143427450/Mathematical_Modelling_of_Epidemic_Spread_and_Control_Strategies?source=swp_share)

## Contents
- `Mathematical_Modelling_of_Epidemic_Spread_and_Control_Strategies.pdf` – Full report  
- `epidemic_sir.m` – Example MATLAB SIR Simulation 
- `example_sir.png` – Example Output

## Abstract
This analysis covers:
- **SIR baseline model** – Formulation, assumptions, and calibration of transmission/recovery rates from Jakarta data.  
- **Reproduction number (R₀)** – Derivation and interpretation; comparison of estimates across model variants.  
- **SEIRDV extension** – Exposed, Death, and Vaccinated compartments with vital dynamics; impact of vaccination uptake.  
- **Scenario analysis** – Exploration of vaccination-rate strategies and indicative resource/budget constraints.  
- **Stability insights** – Equilibrium and Jacobian/eigenvalue reasoning to explain long-run behaviour of the outbreak.  
- **Visualisation** – Time-series trajectories and phase-portrait interpretations for key compartments.  

## Example Code
The included MATLAB script simulates a **basic SIR model** and saves a plot as `epidemic_sir.m`.
![Example Code Output](example_sir.png)

