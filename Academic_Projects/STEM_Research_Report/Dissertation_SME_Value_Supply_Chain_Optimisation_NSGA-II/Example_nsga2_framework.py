"""
Example NSGA-II for Supply Chain Optimisation in SMEs
Brilliant G Purnawan

This script demonstrates a simplified multi-objective optimisation
problem using NSGA-II (via pymoo). It models trade-offs in SME supply
chain design between cost, delivery lead time, and resilience
when transitioning toward Industry 4.0/5.0.

Model Scenario:

Design decisions (x in [0,1]):
- x1 = automation_level ∈ [0,1]
    Higher automation → higher operational cost (CapEx/OpEx) but lower delivery lead time.
- x2 = inventory_buffer ∈ [0,1]
    Higher inventory → higher holding cost but better resilience to disruptions.

Objectives (multi-objective):
1) Minimise operational cost
   cost = 5000*automation + 2000*inventory
   (automation adds CapEx/OpEx; inventory adds holding & working-capital cost)

2) Minimise delivery lead time
   lead_time = 20 - 10*automation + 5*inventory
   (automation shortens processes; larger buffers can slow flow/handling)

3) Maximise resilience  ⟹  Minimise (1 - resilience)
   resilience ↑ with inventory (buffers absorb shocks)
   resilience ↑ with lower rigidity (less over-automated lines)
   We model: (1 - resilience) = 1 - (0.6*inventory + 0.4*(1 - automation))
   So higher inventory and lower automation both improve resilience in this setup.

Notes:
- Coefficients are illustrative to produce realistic trade-offs (Pareto front), not calibrated.
- Use this as a didactic example to visualise cost–time–resilience tensions.
"""

import numpy as np
import matplotlib.pyplot as plt
from pymoo.algorithms.moo.nsga2 import NSGA2
from pymoo.termination import get_termination
from pymoo.optimize import minimize
from pymoo.core.problem import ElementwiseProblem


class SupplyChainProblem(ElementwiseProblem):
    def __init__(self):
        # decision vars: [automation_level, inventory_buffer]
        super().__init__(n_var=2, n_obj=3, n_constr=0,
                         xl=np.array([0.0, 0.0]),
                         xu=np.array([1.0, 1.0]))

    def _evaluate(self, x, out, *args, **kwargs):
        automation, inventory = x

        # Obj 1: Operational Cost (min)
        # Higher automation & inventory both add cost (capex/opex + holding)
        cost = 5000*automation + 2000*inventory

        # Obj 2: Delivery Lead Time (min)
        # Automation reduces time; excess inventory can slow handling/flow
        lead_time = 20 - 10*automation + 5*inventory

        # Obj 3: 1 - Resilience (min)
        # Resilience grows with inventory; too much automation may reduce flexibility
        resilience = 1 - (0.6*inventory + 0.4*(1 - automation))

        out["F"] = [cost, lead_time, resilience]


# Simulated NSGA-II
problem = SupplyChainProblem()
algorithm = NSGA2(pop_size=100)
termination = get_termination("n_gen", 100)

res = minimize(problem, algorithm, termination, seed=42,
               save_history=True, verbose=False)

# --- Plot 2D projections of the Pareto set ---
F = res.F
plt.figure(figsize=(14, 4))

# Cost vs Lead Time
plt.subplot(1, 3, 1)
plt.scatter(F[:, 0], F[:, 1], c="blue", alpha=0.65)
plt.xlabel("Operational Cost [$]")
plt.ylabel("Lead Time [days]")
plt.title("Cost vs Lead Time")

# Cost vs Resilience (show resilience, not 1-resilience)
plt.subplot(1, 3, 2)
plt.scatter(F[:, 0], 1 - F[:, 2], c="green", alpha=0.65)
plt.xlabel("Operational Cost [$]")
plt.ylabel("Resilience")
plt.title("Cost vs Resilience")

# Lead Time vs Resilience
plt.subplot(1, 3, 3)
plt.scatter(F[:, 1], 1 - F[:, 2], c="red", alpha=0.65)
plt.xlabel("Lead Time [days]")
plt.ylabel("Resilience")
plt.title("Lead Time vs Resilience")

plt.tight_layout()
plt.savefig("supply_chain_nsga2.png", dpi=300)
plt.show()
