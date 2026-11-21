from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional
from app.database.store import PREDICTIONS

router = APIRouter()

class XAIExplanationResponse(BaseModel):
    prediction_id: str
    prediction: str
    confidence: float
    shap_features: Dict[str, float]
    lime_features: Dict[str, float]
    human_explanation: str

@router.get("/explanation/{prediction_id}", response_model=XAIExplanationResponse)
def get_explanation(prediction_id: str):
    if prediction_id not in PREDICTIONS:
        raise HTTPException(
            status_code=404,
            detail=f"Explanation for prediction ID '{prediction_id}' not found. Please analyze telemetry via '/prediction/analyze' first."
        )
        
    pred = PREDICTIONS[prediction_id]
    return XAIExplanationResponse(
        prediction_id=prediction_id,
        prediction=pred["prediction"],
        confidence=pred["confidence"],
        shap_features=pred.get("shap_values", {}),
        lime_features=pred.get("lime_values", {}),
        human_explanation=pred.get("generated_reason", "Vehicle behavior evaluated.")
    )
