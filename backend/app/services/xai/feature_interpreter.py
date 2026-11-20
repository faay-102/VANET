from typing import Dict

# Semantic mappings of raw feature names to human-comprehensible descriptions
FEATURE_SEMANTIC_MAP: Dict[str, str] = {
    # 21 Authentic VeReMi Kinematic Features
    "pos_residual": "Dead-reckoning position residual (claimed vs expected physical location)",
    "delta_pos_magnitude": "Actual physical displacement between consecutive BSM messages",
    "delta_pos_x": "X-axis displacement delta",
    "delta_pos_y": "Y-axis displacement delta",
    "speed_mag1": "Initial BSM total velocity magnitude",
    "speed_mag2": "Current BSM total velocity magnitude",
    "delta_spd_magnitude": "Speed variation magnitude between messages",
    "delta_spd_x": "X-axis velocity variation delta",
    "delta_spd_y": "Y-axis velocity variation delta",
    "acceleration_magnitude": "Derived kinematic acceleration magnitude",
    "delta_t": "Time interval between consecutive BSM packets",
    "heading_angle1": "Initial vehicle travel heading angle",
    "heading_angle2": "Current vehicle travel heading angle",
    "pos_x1": "Initial BSM reported X position",
    "pos_y1": "Initial BSM reported Y position",
    "pos_x2": "Current BSM reported X position",
    "pos_y2": "Current BSM reported Y position",
    "spd_x1": "Initial BSM reported X velocity",
    "spd_y1": "Initial BSM reported Y velocity",
    "spd_x2": "Current BSM reported X velocity",
    "spd_y2": "Current BSM reported Y velocity",

    # Legacy / Mock features support
    "speed": "Reported vehicle velocity",
    "acceleration": "Reported acceleration",
    "heading": "Reported heading",
    "lane_position": "Lane index position",
    "message_frequency": "Unusual communication frequency",
    "message_interval": "Message interval delta timing",
    "neighbor_count": "Local vehicle density (neighbor count)",
    "communication_rate": "Message beaconing frequency",
    "packet_count": "Historical packet sequence count",
    "speed_change_rate": "Sudden speed variation",
    "position_change_rate": "Displacement speed mapping",
    "distance_difference": "GPS displacement distance",
    "trajectory_consistency": "Trajectory consistency matching",
    "message_consistency": "Message payload consistency verification",
    "GPS_consistency": "GPS location inconsistency",
    "speed_anomaly_score": "Abrupt velocity deviation",
    "position_anomaly_score": "GPS coordinate displacement inconsistency",
    "message_frequency_anomaly": "Unusual communication frequency",
    "acceleration_anomaly": "Abnormal acceleration pattern",
    "trajectory_deviation": "Suspicious movement trajectory",
    "communication_behavior_score": "Communication transmission density score"
}

class FeatureInterpreter:
    """
    Translates raw database feature codes and variables 
    into semantically rich, operator-readable descriptions.
    """
    def __init__(self, semantic_map: Dict[str, str] = FEATURE_SEMANTIC_MAP):
        self.semantic_map = semantic_map

    def interpret(self, feature_name: str) -> str:
        """
        Retrieves human-readable description for a raw feature column name.
        """
        return self.semantic_map.get(feature_name, f"Feature ({feature_name})")
