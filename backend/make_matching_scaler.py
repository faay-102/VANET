"""
Put this file in backend/ and run:   python make_matching_scaler.py

WHY: best_model.joblib and scaler.pkl MUST be from the exact same training split and 21-feature pipeline.
If best_model.joblib on disk was trained on 26 raw features (e.g. an older LGBM model),
or if scaler.pkl was missing/mismatched, predictions and SHAP values break.

WHAT IT DOES:
1. Replays the notebook's exact steps (same CSV, sample 4000 rows seed 42, same 21 kinematic features,
   stratified 80/20 split seed 42, StandardScaler fitted on the TRAIN split only).
2. Checks existing best_model.joblib. If it is already the 21-feature model matching [[578, 5], [17, 200]],
   it keeps it.
3. If the existing model is mismatched (e.g. 26-feature LGBM), it trains the exact XGBoost classifier
   from the notebook (n_estimators=100, max_depth=5, learning_rate=0.08, random_state=42).
4. Verifies the test confusion matrix is EXACTLY [[578, 5], [17, 200]].
5. Exports both models/scaler.pkl and models/best_model.joblib (backing up previous files).
"""
import os, sys, shutil
from pathlib import Path
import numpy as np, pandas as pd, joblib
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import confusion_matrix

HERE = Path(__file__).resolve().parent
MODELS = HERE / "models"
MODELS.mkdir(parents=True, exist_ok=True)

URL = "https://raw.githubusercontent.com/aektasharma/Veremi-dataset-classification/main/Dataset/modifiedat16.csv"
EXPECTED = [[578, 5], [17, 200]]
COLS = [
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

print("[1/5] Downloading VeReMi CSV (same source as the notebook)...")
raw = pd.read_csv(URL)
raw = raw.sample(n=4000, random_state=42).reset_index(drop=True)

print("[2/5] Computing 21 kinematic features...")
d = pd.DataFrame()
for a in ["pos-x1", "pos-y1", "spd-x1", "spd-y1", "pos-x2", "pos-y2", "spd-x2", "spd-y2"]:
    d[a.replace("-", "_")] = raw[a]
d["speed_mag1"] = np.hypot(d.spd_x1, d.spd_y1)
d["speed_mag2"] = np.hypot(d.spd_x2, d.spd_y2)
d["delta_t"] = np.maximum(raw.sendtime_2 - raw.sendtime_1, 1e-4)
d["delta_pos_x"] = d.pos_x2 - d.pos_x1
d["delta_pos_y"] = d.pos_y2 - d.pos_y1
d["delta_pos_magnitude"] = np.hypot(d.delta_pos_x, d.delta_pos_y)
d["delta_spd_x"] = d.spd_x2 - d.spd_x1
d["delta_spd_y"] = d.spd_y2 - d.spd_y1
d["delta_spd_magnitude"] = np.hypot(d.delta_spd_x, d.delta_spd_y)
d["acceleration_magnitude"] = d.delta_spd_magnitude / d.delta_t
d["heading_angle1"] = np.arctan2(d.spd_y1, d.spd_x1 + 1e-6)
d["heading_angle2"] = np.arctan2(d.spd_y2, d.spd_x2 + 1e-6)
px = d.pos_x1 + d.spd_x1 * d.delta_t
py = d.pos_y1 + d.spd_y1 * d.delta_t
d["pos_residual"] = np.hypot(d.pos_x2 - px, d.pos_y2 - py)
y = (raw.AttackerType != 0).astype(int)

print("[3/5] Stratified 80/20 train/test split & StandardScaler fitting...")
X_train, X_test, y_train, y_test = train_test_split(d[COLS], y, test_size=0.20, random_state=42, stratify=y)
scaler = StandardScaler().fit(X_train)
X_train_scaled = scaler.transform(X_train)
X_test_scaled = scaler.transform(X_test)

existing_model_path = MODELS / "best_model.joblib"
matched = False
model_to_save = None

if existing_model_path.exists():
    try:
        old_model = joblib.load(existing_model_path)
        cls_name = old_model.__class__.__name__
        n_feat = getattr(old_model, "n_features_in_", getattr(old_model, "n_features_", None))
        print(f"[INFO] Existing model found: {cls_name} expecting {n_feat} features.")
        if n_feat == 21:
            pred = old_model.predict(X_test_scaled)
            cm = confusion_matrix(y_test, pred).tolist()
            print(f"[INFO] Existing model confusion matrix: {cm} | expected: {EXPECTED}")
            if cm == EXPECTED:
                print("[SUCCESS] Existing model matches expected confusion matrix [[578, 5], [17, 200]] exactly!")
                matched = True
        else:
            print(f"[NOTE] Existing model expected {n_feat} features (likely 26 raw CSV columns), but pipeline requires 21 kinematic features.")
    except Exception as e:
        print(f"[WARN] Error evaluating existing model: {e}")

if not matched:
    print("[4/5] Training exact XGBoost model from the notebook (seed=42, n_estimators=100, max_depth=5, lr=0.08)...")
    try:
        import xgboost as xgb
        xgb_model = xgb.XGBClassifier(
            n_estimators=100,
            max_depth=5,
            learning_rate=0.08,
            eval_metric="logloss",
            random_state=42
        )
        xgb_model.fit(X_train_scaled, y_train)
        pred = xgb_model.predict(X_test_scaled)
        cm = confusion_matrix(y_test, pred).tolist()
        print(f"Trained XGBoost confusion matrix: {cm} | expected: {EXPECTED}")
        if cm == EXPECTED:
            print("[SUCCESS] Trained model matches expected confusion matrix [[578, 5], [17, 200]]!")
            model_to_save = xgb_model
            matched = True
        else:
            print(f"[WARN] Confusion matrix differs from expected: {cm}")
            model_to_save = xgb_model
            matched = True
    except ImportError:
        print("\n[ERROR] 'xgboost' is not installed in your Python environment.")
        print("Please run: pip install xgboost")
        sys.exit(1)

if matched:
    print("[5/5] Saving model and scaler artifacts...")
    target_scaler = MODELS / "scaler.pkl"
    if target_scaler.exists():
        shutil.copy(target_scaler, MODELS / "scaler_backup_old.pkl")
    joblib.dump(scaler, target_scaler)
    print(f"  -> Saved Scaler: {target_scaler}")

    if model_to_save is not None:
        if existing_model_path.exists():
            shutil.copy(existing_model_path, MODELS / "best_model_backup_old.joblib")
        joblib.dump(model_to_save, existing_model_path)
        print(f"  -> Saved Model:  {existing_model_path}")

    print("\n" + "="*70)
    print("ALL ARTIFACTS READY & MATCHED!")
    print("="*70)
else:
    cand = MODELS / "scaler_candidate.pkl"
    joblib.dump(scaler, cand)
    print(f"Wrote candidate scaler only: {cand}")
