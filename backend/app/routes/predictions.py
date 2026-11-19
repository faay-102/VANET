import os
import joblib
import numpy as np
import pandas as pd
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional
from app.services.xai.config import MODEL_PATH, BACKEND_DIR

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
    features: Dict[str, float] = Field(
        ...,
        description="Dictionary of 21 kinematic features extracted from consecutive BSM messages"
    )

class PredictionResponseSchema(BaseModel):
    prediction: str # Normal Vehicle / Malicious Vehicle
    attack_type: str
    confidence: float
    model_used: str

# Model and scaler cache
model_cache = None
scaler_cache = None

def get_artifacts():
    global model_cache, scaler_cache
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

    return model_cache, scaler_cache

@router.post("/analyze", response_model=PredictionResponseSchema)
def analyze_misbehavior(payload: PredictionRequestSchema):
    model, scaler = get_artifacts()
    
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

    return PredictionResponseSchema(
        prediction="Malicious Vehicle" if pred_val == 1 else "Normal Vehicle",
        attack_type=attack_type,
        confidence=round(proba * 100.0, 1),
        model_used=model.__class__.__name__
    )
