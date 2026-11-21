import networkx as nx
from app.services.routing.route_config import (
    WEIGHT_DISTANCE,
    WEIGHT_CONGESTION,
    WEIGHT_ACCIDENT_RISK
)

class RouteScorer:
    """
    Evaluates dynamic edge cost coefficients factoring distance, congestion, 
    and blockages.
    """
    def calculate_edge_cost(self, u: str, v: str, edge_attrs: dict, vehicle_type: str = "Standard") -> float:
        """
        Computes dynamic cost value for an edge. Returns a massive number if blocked.
        Accounts for vehicle_type (e.g. Emergency vehicles with corridor clearance).
        """
        if edge_attrs.get("road_status") == "BLOCKED":
            return 1e9 # Infinite cost (Blocked)

        distance = edge_attrs.get("distance", 1.0)
        density = edge_attrs.get("traffic_density", 0.0)
        accident = edge_attrs.get("accident_status", False)

        # Scale traffic density (0 to 100) to match distance scale
        traffic_factor = density / 10.0 # scale factor to normalize cost

        # Scale accident status risk
        accident_factor = 50.0 if accident else 0.0

        # Adjust weights dynamically based on vehicle_type
        is_emergency = vehicle_type.lower() in ["ambulance", "police", "fire brigade", "rescue", "emergency"]
        w_cong = WEIGHT_CONGESTION * (0.6 if is_emergency else 1.0)
        w_dist = WEIGHT_DISTANCE * (1.2 if is_emergency else 1.0)
        w_acc = WEIGHT_ACCIDENT_RISK * (1.5 if is_emergency else 1.0)

        # Compute dynamic cost
        cost = (
            (distance * w_dist) +
            (traffic_factor * w_cong) +
            (accident_factor * w_acc)
        )
        return float(cost)

    def apply_costs_to_graph(self, graph: nx.Graph, vehicle_type: str = "Standard") -> None:
        """
        Applies calculated cost scores onto graph edges under the weight name 'cost'.
        """
        for u, v, attrs in graph.edges(data=True):
            graph[u][v]["cost"] = self.calculate_edge_cost(u, v, attrs, vehicle_type=vehicle_type)
            # Travel time estimation in seconds: Distance / (Speed Limit adjusted by traffic)
            speed = attrs.get("speed_limit", 50.0)
            density = attrs.get("traffic_density", 0.0)
            
            is_emergency = vehicle_type.lower() in ["ambulance", "police", "fire brigade", "rescue", "emergency"]
            speed_bonus = 1.15 if is_emergency else 1.0
            
            # Reduce speed dynamically as traffic density increases
            adjusted_speed = speed * speed_bonus * (1.0 - (density / (140.0 if is_emergency else 120.0)))
            adjusted_speed = max(adjusted_speed, 10.0 if is_emergency else 5.0)
            
            # Time = Distance (km) / Speed (km/h) * 3600 (seconds/hour)
            graph[u][v]["travel_time"] = (attrs.get("distance", 1.0) / adjusted_speed) * 3600.0
