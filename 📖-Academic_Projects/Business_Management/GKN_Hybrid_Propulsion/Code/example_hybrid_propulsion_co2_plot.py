"""
Example CO₂ Reduction Plotter for Hybrid-Electric Propulsion
Author: Brilliant G. Purnawan

This example Python script plots estimated CO₂ savings across different hybridisation levels,
showing how partial electrification impacts aircraft emissions. Calculations are simplified for visual.
"""

import matplotlib.pyplot as plt
import numpy as np

def co2_savings_curve(baseline_emissions):
    """
    Generating arrays of hybridisation levels and corresponding CO₂ savings.
    """
    hybrid_levels = np.linspace(0, 100, 101)  # 0–100% in steps of 1%
    savings = baseline_emissions * (hybrid_levels / 100.0)
    remaining = baseline_emissions - savings
    return hybrid_levels, savings, remaining

if __name__ == "__main__":
    print("Hybrid Propulsion CO₂ Reduction Plot")
    baseline = float(input("Baseline CO₂ emissions per flight [kg]: "))

    hybrid_levels, savings, remaining = co2_savings_curve(baseline)

    # Plot savings
    plt.figure(figsize=(8, 5))
    plt.plot(hybrid_levels, savings, label="CO₂ Savings", color="blue")
    plt.plot(hybrid_levels, remaining, label="Remaining Emissions", color="red")
    plt.axhline(y=baseline, color="gray", linestyle="--", label="Baseline Emissions")

    plt.title("Estimated CO₂ Impact of Hybrid-Electric Propulsion")
    plt.xlabel("Hybridisation Level [%]")
    plt.ylabel("CO₂ [kg per flight]")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig("co2_savings_curve.png", dpi=300)
    plt.show()
