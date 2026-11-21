import os
import uuid
import joblib
import numpy as np
import pandas as pd
from datetime import datetime
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional
from app.services.xai.config import MODEL_PATH, BACKEND_DIR
from app.database.store import PREDICTIONS, TRUST_SCORES
from app.services.trust_engine import TrustEngine
from app.services.xai.explanation_generator import ExplanationGenerator

router = APIRouter()

SCALER_PATH = BACKEND_DIR / "models" / "scaler.pkl"

# Exact 21 Kinematic Features from authentic VeReMi Attack 16 pipeline
FEATURE_COLUMNS = [
    "pos_x1", "pos_y1", "spd_x1", "spd_y1",
    "pos_x2", "pos_y2", "spd_x2", "spd_y2",
    "speed_mag1", "speed_mag2",
    "delta_t",
    "delta_pos_x", "delta_pos_y", "delta_pos_magnitude",
    "delta_spd_x", "delta_spd_y", "delta_spd_magnitude",
    "acceleration_magnitude",
    "heading_angle1", "heading_angle2",
    "pos_residual"
]

class PredictionRequestSchema(BaseModel):
    vehicle_id: Optional[str] = "VEH_TEST"
    features: Dict[str, float] = Field(
        ...,
        description="Dictionary of 21 kinematic features extracted from consecutive BSM messages"
    )

class PredictionResponseSchema(BaseModel):
    prediction_id: str
    vehicle_id: str
    prediction: str # Normal Vehicle / Malicious Vehicle
    attack_type: str
    confidence: float
    model_used: str
    explanation: Optional[str] = None
    trust_score: Optional[float] = None
    trust_status: Optional[str] = None

# Model, scaler, explainer and trust engine cache
model_cache = None
scaler_cache = None
tree_explainer_cache = None
explainer_gen = ExplanationGenerator()
trust_engine_inst = TrustEngine()

def get_artifacts():
    global model_cache, scaler_cache, tree_explainer_cache
    if model_cache is None:
        if not os.path.exists(MODEL_PATH):
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Trained model not found at '{MODEL_PATH}'. Please export 'best_model.joblib' from Colab."
            )
        try:
            model_cache = joblib.load(MODEL_PATH)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed loading model binary: {str(e)}"
            )

    if scaler_cache is None and os.path.exists(SCALER_PATH):
        try:
            scaler_cache = joblib.load(SCALER_PATH)
        except Exception as e:
            print(f"[WARN] Failed loading scaler from '{SCALER_PATH}': {str(e)}")

    if tree_explainer_cache is None and model_cache is not None:
        try:
            import shap
            tree_explainer_cache = shap.TreeExplainer(model_cache)
        except Exception as e:
            print(f"[INFO] shap.TreeExplainer not available, using tree attribution: {str(e)}")
            tree_explainer_cache = None

    return model_cache, scaler_cache, tree_explainer_cache

def get_model():
    """Convenience alias for legacy callers."""
    model, _, _ = get_artifacts()
    return model

@router.post("/analyze", response_model=PredictionResponseSchema)
def analyze_misbehavior(payload: PredictionRequestSchema):
    model, scaler, tree_explainer = get_artifacts()
    
    # Determine expected columns (from model metadata or standard 21 features)
    if hasattr(model, "feature_names_in_"):
        expected_cols = list(model.feature_names_in_)
    else:
        expected_cols = FEATURE_COLUMNS

    # Strict check: Ensure scaler is loaded (model was trained on scaled data)
    if scaler is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Scaler artifact not found at '{SCALER_PATH}'. Both 'best_model.joblib' and 'scaler.pkl' are required."
        )

    # Validate that all required features are present in payload
    feats = payload.features
    missing_feats = [col for col in expected_cols if col not in feats]
    if missing_feats:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Missing required feature(s): {missing_feats}. Exactly {len(expected_cols)} features expected."
        )

    # Validation: Check finite numeric values
    for col in expected_cols:
        val = float(feats[col])
        if not np.isfinite(val):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Feature '{col}' contains non-finite value: {val}."
            )

    # Validation: Check positive delta_t
    delta_t_val = float(feats.get("delta_t", 0.0))
    if delta_t_val <= 0.0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Feature 'delta_t' must be strictly positive (> 0). Provided: {delta_t_val}."
        )
    
    # Extract feature values in exact required column order
    row = {col: float(feats[col]) for col in expected_cols}
    df = pd.DataFrame([row], columns=expected_cols)
    
    # Apply StandardScaler transform
    try:
        X_input = scaler.transform(df)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Scaler transformation failed: {str(e)}"
        )
        
    try:
        pred_val = int(model.predict(X_input)[0])
        proba = float(model.predict_proba(X_input)[0][pred_val])
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Prediction inference failed: {str(e)}"
        )

    # Resolve attack type based on kinematic features
    attack_type = "NONE"
    if pred_val == 1:
        pos_res = feats.get("pos_residual", 0.0)
        accel_mag = feats.get("acceleration_magnitude", 0.0)
        
        if pos_res > 2.0:
            attack_type = "EventualStop (Position Falsification)"
        elif accel_mag > 20.0:
            attack_type = "Kinematic Anomaly (Abnormal Acceleration)"
        else:
            attack_type = "VeReMi Attack 16"

    # Compute Real SHAP Feature Attributions via TreeExplainer
    prediction_id = str(uuid.uuid4())
    vehicle_id = payload.vehicle_id or "VEH_TEST"
    
    calculated_shap = {}
    if tree_explainer is not None:
        try:
            raw_shap = tree_explainer.shap_values(X_input)
            if isinstance(raw_shap, list):
                raw_shap = raw_shap[1] if len(raw_shap) > 1 else raw_shap[0]
            elif hasattr(raw_shap, "shape") and len(raw_shap.shape) == 3:
                raw_shap = raw_shap[:, :, 1]
            flat_shap = np.array(raw_shap).flatten()
            for col, val in zip(expected_cols, flat_shap):
                calculated_shap[col] = round(float(val), 4)
        except Exception as e:
            print(f"[WARN] TreeSHAP inference error: {e}")

    # Compute Local Perturbation LIME Sensitivity Weights (dP/dX local gradient surrogate)
    calculated_lime = {}
    try:
        base_malicious_prob = float(model.predict_proba(X_input)[0][1])
        for idx, col in enumerate(expected_cols):
            X_pert = X_input.copy()
            X_pert[0, idx] += 0.1 # Perturb normalized z-score
            prob_pert = float(model.predict_proba(X_pert)[0][1])
            # Finite difference local linear coefficient
            calculated_lime[col] = round(float((prob_pert - base_malicious_prob) / 0.1), 4)
    except Exception as e:
        print(f"[WARN] Local LIME perturbation error: {e}")
    
    explanation_text = explainer_gen.generate_local_reason(
        prediction=pred_val,
        confidence=proba,
        shap_values=calculated_shap,
        lime_values=calculated_lime
    )

    # Store in PREDICTIONS store so GET /xai/explanation/{id} resolves live!
    PREDICTIONS[prediction_id] = {
        "prediction_id": prediction_id,
        "vehicle_id": vehicle_id,
        "prediction": "Malicious Vehicle" if pred_val == 1 else "Normal Vehicle",
        "confidence": round(proba * 100.0, 1),
        "attack_type": attack_type,
        "shap_values": calculated_shap,
        "lime_values": calculated_lime,
        "generated_reason": explanation_text,
        "timestamp": datetime.utcnow().isoformat()
    }

    # Automatically Update Vehicle Trust Standing
    db_trust = trust_engine_inst.process_telemetry_event(
        vehicle_id=vehicle_id,
        prediction=pred_val,
        attack_type=attack_type,
        xai_lime_values=calculated_lime,
        message_features=feats
    )
    TRUST_SCORES[vehicle_id] = db_trust

    return PredictionResponseSchema(
        prediction_id=prediction_id,
        vehicle_id=vehicle_id,
        prediction="Malicious Vehicle" if pred_val == 1 else "Normal Vehicle",
        attack_type=attack_type,
        confidence=round(proba * 100.0, 1),
        model_used=model.__class__.__name__,
        explanation=explanation_text,
        trust_score=db_trust.get("current_score", 100.0),
        trust_status=db_trust.get("trust_status", "Trusted Vehicle")
    )
