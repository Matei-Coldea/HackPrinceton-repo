from typing import List, Dict
import warnings

try:
    from qiskit import Aer
    from qiskit.utils import algorithm_globals
    from qiskit.algorithms import QAOA
    from qiskit.algorithms.optimizers import COBYLA
    from qiskit_optimization import QuadraticProgram
    from qiskit_optimization.algorithms import MinimumEigenOptimizer
    QISKIT_AVAILABLE = True
except ImportError:
    QISKIT_AVAILABLE = False
    warnings.warn(
        "Qiskit not installed. Falling back to classical greedy algorithm.",
        UserWarning
    )


def build_knapsack_qp(optional_events: List[Dict], B_opt: float) -> 'QuadraticProgram':
    if not QISKIT_AVAILABLE:
        raise ImportError("Qiskit is not available")
    
    qp = QuadraticProgram()
    n = len(optional_events)
    
    for i in range(n):
        qp.binary_var(name=f"x_{i}")
    
    linear_obj = {f"x_{i}": float(ev["importance"]) for i, ev in enumerate(optional_events)}
    qp.maximize(linear=linear_obj)
    
    linear_constr = {f"x_{i}": float(ev["amount"]) for i, ev in enumerate(optional_events)}
    qp.linear_constraint(
        linear=linear_constr,
        sense="<=",
        rhs=float(B_opt),
        name="budget"
    )
    
    return qp


def solve_knapsack_qaoa(optional_events: List[Dict], B_opt: float, 
                        reps: int = 1) -> List[Dict]:
    if not optional_events or B_opt <= 0:
        return []
    
    if not QISKIT_AVAILABLE:
        return _classical_greedy_knapsack(optional_events, B_opt)
    
    try:
        qp = build_knapsack_qp(optional_events, B_opt)
        algorithm_globals.random_seed = 42
        backend = Aer.get_backend("statevector_simulator")
        
        qaoa = QAOA(
            optimizer=COBYLA(),
            reps=reps,
            quantum_instance=backend
        )
        
        optimizer = MinimumEigenOptimizer(qaoa)
        result = optimizer.solve(qp)
        
        chosen_events = []
        for i, ev in enumerate(optional_events):
            if result.x[i] > 0.5:
                chosen_events.append(ev)
        
        return chosen_events
        
    except Exception as e:
        warnings.warn(
            f"Quantum solver failed ({str(e)}), falling back to classical",
            UserWarning
        )
        return _classical_greedy_knapsack(optional_events, B_opt)


def _classical_greedy_knapsack(events: List[Dict], budget: float) -> List[Dict]:
    sorted_events = sorted(
        events,
        key=lambda e: e["importance"] / max(e["amount"], 0.01),
        reverse=True
    )
    
    chosen = []
    remaining_budget = budget
    
    for event in sorted_events:
        if event["amount"] <= remaining_budget:
            chosen.append(event)
            remaining_budget -= event["amount"]
    
    return chosen


def quantum_select_optional_events(optional_events: List[Dict], 
                                   budget_for_optional: float) -> List[Dict]:
    return solve_knapsack_qaoa(optional_events, budget_for_optional)


