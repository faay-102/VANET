"""
One-shot smoke test. Run it yourself against the running backend and paste the output.

  1) uvicorn app.main:app --port 8000        (from backend/, in another terminal)
  2) python smoke_test.py                     (BASE below if your prefix differs)

Expected values were derived from the code and a replica of your XGBoost (NOT from a real run),
so a FAIL means "differs from prediction", not necessarily "bug": read the printed actual value.
Restart the server afterwards: accidents are kept in memory and trust history stays on disk
(each run uses fresh vehicle ids, so trust history does not affect it).
"""
import json, time, urllib.request, urllib.error

BASE = "http://localhost:8000/api/v1"
MAL = json.load(open("test_malicious.json"))["features"]
NOR = json.load(open("test_normal.json"))["features"]
results = []

def call(method, path, body=None):
    req = urllib.request.Request(BASE + path, method=method,
                                 data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status, json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, {"error": e.read().decode()[:300]}
    except Exception as e:
        return 0, {"error": str(e)}

def check(name, ok, actual):
    results.append(ok)
    print(("PASS" if ok else "FAIL"), "|", name, "| actual:", actual)

def near(a, b, tol=0.06):
    return isinstance(a, (int, float)) and abs(a - b) <= tol

tag = str(int(time.time()))
v1, v2 = "SMOKE_A_" + tag, "SMOKE_B_" + tag

# ---- 0. preflight: show the real error if /prediction/analyze fails -------------------------
st0, r0 = call("POST", "/prediction/analyze", {"vehicle_id": "SMOKE_PRE_" + tag, "features": MAL})
print("PREFLIGHT /prediction/analyze -> HTTP", st0)
if st0 != 200:
    print("RESPONSE BODY:", r0)
    print("\nFix this first (copy the line above), then re-run. Common causes:")
    print("  503 'Trained model not found' / 'Scaler artifact not found' -> put best_model.joblib and scaler.pkl in backend/models/")
    print("  404 -> check the path/prefix (api.py)    422 -> a feature is missing    500 -> see 'detail' above")
    raise SystemExit(1)

# ---- 1. detection -> explanation -> trust chain -------------------------------------------
first_id = None
for i, exp in enumerate([71.0, 57.8, 50.0], 1):
    st, r = call("POST", "/prediction/analyze", {"vehicle_id": v1, "features": MAL})
    if i == 1:
        first_id = r.get("prediction_id")
        check("malicious predicted Malicious", r.get("prediction") == "Malicious Vehicle", r.get("prediction"))
        check("confidence about 99.9", near(r.get("confidence"), 99.9, 0.3), r.get("confidence"))
    check(f"trust after malicious call {i} = {exp}", near(r.get("trust_score"), exp), r.get("trust_score"))
st, r = call("POST", "/prediction/analyze", {"vehicle_id": v1, "features": NOR})
check("normal predicted Normal", r.get("prediction") == "Normal Vehicle", r.get("prediction"))
check("trust after clean call = 85.6", near(r.get("trust_score"), 85.6), r.get("trust_score"))

st, x = call("GET", f"/xai/explanation/{first_id}")
shap = x.get("shap_features", {}) or {}
lime = x.get("lime_features", {}) or {}
check("explanation endpoint returns data", st == 200 and bool(shap), st)
check("SHAP delta_pos_magnitude about +3.1", 2.5 <= shap.get("delta_pos_magnitude", -99) <= 3.7, shap.get("delta_pos_magnitude"))
check("SHAP not the old placeholder 0.45/0.28/0.22", shap.get("speed_mag2") != 0.28, shap.get("speed_mag2"))
check("sensitivity values tiny (<= 0.0134)", all(v <= 0.0134 for v in lime.values()) if lime else False, max(lime.values()) if lime else None)

# ---- 2. emergency penalty ------------------------------------------------------------------
st, r = call("POST", "/emergency/verify", {"vehicle_id": v2, "authorization_id": "WRONG_TOKEN",
                                           "emergency_type": "Ambulance"})
check("wrong token is rejected", r.get("is_authenticated") is False, r)
st, t = call("GET", f"/trust/{v2}")
check("trust after one fake claim = 55.0", near(t.get("trust_score"), 55.0), t.get("trust_score"))
st, r = call("POST", "/prediction/analyze", {"vehicle_id": v2, "features": NOR})
check("trust after next clean packet = 87.1 (penalty persisted)", near(r.get("trust_score"), 87.1), r.get("trust_score"))

# ---- 3. routing (run last, then restart the server) -----------------------------------------
st, r = call("POST", "/routing/recommend", {"source": "A", "destination": "F"})
check("default route A-D-C-F", r.get("recommended_route") == ["A", "D", "C", "F"], r.get("recommended_route"))
call("POST", "/routing/accidents/", {"accident_id": "SMOKE_ACC_" + tag, "severity": "High",
                                     "affected_roads": ["ROAD_DC"]})
st, r = call("POST", "/routing/recommend", {"source": "A", "destination": "F"})
check("route avoids blocked ROAD_DC (A-B-C-F)", r.get("recommended_route") == ["A", "B", "C", "F"], r.get("recommended_route"))

print(f"\n{sum(results)}/{len(results)} checks match the predictions")
