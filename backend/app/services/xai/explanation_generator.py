from typing import Dict, Any, List
from app.services.xai.feature_interpreter import FeatureInterpreter

class ExplanationGenerator:
    """
    Translates numeric SHAP/LIME contribution vectors and prediction statuses
    into natural, operator-friendly explanatory paragraphs.
    """
    def __init__(self, interpreter: FeatureInterpreter = None):
        self.interpreter = interpreter or FeatureInterpreter()

    def generate_local_reason(
        self, 
        prediction: int, 
        confidence: float, 
        shap_values: Dict[str, float], 
        lime_values: Dict[str, float]
    ) -> str:
        """
        Converts classification outcomes and top feature metrics into a sentence.
        """
        # If prediction indicates normal behavior (0)
        if prediction == 0:
            return "Vehicle behavior is normal. No significant anomalies detected."

        # Filter features that increase the probability of malicious classification (positive values)
        # Combine SHAP and LIME to select the most significant contributors
        contributing_factors = []
        for feature, val in lime_values.items():
            if val > 0.01: # Filter trace noise contributions
                contributing_factors.append((feature, val))

        # Sort by weight contribution desc
        contributing_factors.sort(key=lambda x: x[1], reverse=True)

        if not contributing_factors:
            # Fallback to SHAP values if LIME values are too low
            for feature, val in shap_values.items():
                if val > 0.0:
                    contributing_factors.append((feature, val))
            contributing_factors.sort(key=lambda x: x[1], reverse=True)

        # Select top 3 contributing factors
        top_factors = contributing_factors[:3]

        if not top_factors:
            return (
                f"The vehicle was classified as malicious (confidence: {confidence*100:.1f}%) "
                "due to minor anomalies across multiple kinematic and communication features."
            )

        # Translate feature columns into semantic descriptions
        phrases = []
        for feat_name, _ in top_factors:
            # Customized descriptions for VeReMi 21 kinematic features & attack scenarios
            if feat_name in ["pos_residual", "position_anomaly_score", "GPS_consistency"]:
                phrases.append("dead-reckoning position mismatch (claimed vs expected physical location)")
            elif feat_name in ["delta_pos_magnitude", "distance_difference"]:
                phrases.append("frozen physical displacement despite reported movement")
            elif feat_name in ["speed_mag1", "speed_mag2", "speed_anomaly_score", "speed_change_rate"]:
                phrases.append("abnormal vehicle velocity telemetry")
            elif feat_name in ["acceleration_magnitude", "acceleration_anomaly", "acceleration"]:
                phrases.append("abnormal kinematic acceleration patterns")
            elif feat_name in ["delta_spd_magnitude", "delta_spd_x", "delta_spd_y"]:
                phrases.append("sharp speed variations across consecutive packets")
            elif feat_name in ["pos_x1", "pos_y1", "pos_x2", "pos_y2"]:
                phrases.append("unrealistic spatial coordinate discrepancies in BSM trajectory")
            elif feat_name in ["spd_x1", "spd_y1", "spd_x2", "spd_y2"]:
                phrases.append("unrealistic directional velocity components")
            elif feat_name in ["heading_angle1", "heading_angle2"]:
                phrases.append("irregular heading trajectory angle")
            elif feat_name in ["delta_t"]:
                phrases.append("irregular inter-packet arrival time intervals")
            elif feat_name in ["message_frequency", "message_frequency_anomaly"]:
                phrases.append("unusually high communication frequency")
            else:
                phrases.append(self.interpreter.interpret(feat_name).lower())

        # Construct final sentence representation
        if len(phrases) == 1:
            reasons_str = phrases[0]
        elif len(phrases) == 2:
            reasons_str = f"{phrases[0]} and {phrases[1]}"
        else:
            reasons_str = f"{phrases[0]}, {phrases[1]}, and {phrases[2]}"

        reason = (
            f"The vehicle was detected as malicious because "
            f"it showed {reasons_str}."
        )
        return reason
