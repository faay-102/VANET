# Explainable AI-Based Misbehavior Detection and Trust Management System for VANET with Emergency Vehicle Priority Management

This repository contains the complete Final Year Project (FYP) codebase for an **Explainable AI-Based Misbehavior Detection and Trust Management System for VANET with Emergency Vehicle Priority Management**.

---

## 1. Project Abstract & Objectives

Vehicular Ad Hoc Networks (VANETs) enable intelligent transport services through Vehicle-to-Vehicle (V2V) and Vehicle-to-Infrastructure (V2I) communication. However, their open wireless topologies make them vulnerable to telemetry manipulation (False Position, False Speed, Sybil, DoS attacks).

This project implements a hybrid security framework combining:
*   **Machine Learning (XGBoost/LightGBM)**: Real-time classification of malicious vehicular kinematic behavior.
*   **Explainable AI (SHAP and LIME)**: Transparent local explanations detailing exactly *why* a vehicle was flagged as malicious.
*   **Dynamic Trust Management Engine**: Continuous scoring of vehicle credibility based on direct evaluation, attack history, message consistency, and explanation confidence.
*   **Emergency Vehicle Priority Management**: Authentication and preemption control for ambulances, fire brigades, police, and rescue units.
*   **Intelligent Detour Routing Solver**: Fast A* and Dijkstra algorithms to recommend safe, congestion-free routes for prioritized vehicles.

---

## 2. Technology Stack

### Backend Services
*   **FastAPI**: High-performance, asynchronous REST APIs.
*   **SQLAlchemy / PostgreSQL**: Database abstraction and relational persistence.
*   **SHAP & LIME**: Local explanation generation engines.
*   **Scikit-Learn, XGBoost, LightGBM, CatBoost**: Anomaly classification models.
*   **Firebase Admin SDK**: Real-time Firebase Cloud Messaging (FCM) notifications.
*   **Pytest**: Asynchronous client integration test suite.

### Mobile Client
*   **Flutter**: Material 3 cross-platform dashboard client.
*   **Riverpod / Provider**: High-performance reactive state management.
*   **GoRouter**: Declared type-safe navigation routing.
*   **Dio**: HTTP and WebSocket communication client.
*   **FL Chart**: Real-time interactive trust history graphs.

---

## 3. Directory Layout (Clean Architecture)

```text
fyp/
│
├── README.md                           # Main Project Master Documentation (This File)
│
├── colab/                              # Google Colab ML Training & Evaluation Notebook
│   └── VANET_Misbehavior_Detection_Colab.ipynb # 6-Model Benchmark, Train/Test Split, ROC & SHAP
│
├── frontend/                           # Flutter 3.41.7 Cross-Platform App & Dashboard
│   ├── lib/
│   │   ├── core/                       # Navigation, theme configurations, API network client
│   │   ├── models/                     # Vehicle, Trust, Route, Alert data structures
│   │   ├── services/                   # Backend API integrations & state managers
│   │   └── features/                   # Dashboard, Auth, Driver, Alerts, and XAI screens
│   ├── test/
│   │   └── widget_test.dart            # Flutter Riverpod UI & state test suite
│   ├── pubspec.yaml                    # Flutter dependencies & assets
│   ├── web/                            # Web build targets
│   └── windows/                        # Windows desktop build targets
│
├── backend/                            # FastAPI Backend, Services, Models & Scripts
│   ├── app/                            # REST API Core Layer & Business Services
│   │   ├── database/                   # Model declarations & mock database store
│   │   ├── dependencies/               # FastAPI route dependencies & auth
│   │   ├── interactors/                # Endpoint-specific business workflows
│   │   ├── routes/                     # HTTP and WebSocket controllers
│   │   └── services/                   # Business domain services (ML, XAI, Trust, Routing, Dataset)
│   ├── models/                         # Trained ML model weights (Imported from Colab)
│   │   ├── best_model.joblib           # Pre-trained XGBoost classifier binary (97.2% Accuracy, 0.997 ROC-AUC)
│   │   └── scaler.pkl                  # Fitted StandardScaler artifact (21 kinematic features)
│   ├── scripts/                        # Standalone runnable simulation scripts
│   │   ├── simulate_trust.py           # 5-Epoch vehicle trust evolution simulation
│   │   ├── simulate_emergency.py       # Priority validation & siren control tester
│   │   ├── simulate_routing.py         # A* emergency detour search runner
│   │   └── simulate_notifications.py   # Real-time FCM push notification simulation
│   ├── tests/                          # Asynchronous API & Unit Test Suite
│   │   ├── conftest.py                 # Async testing client fixtures
│   │   ├── test_api.py                 # Comprehensive REST endpoints test runner
│   │   ├── test_backend.py             # Domain logic integration tests
│   │   └── test_health.py              # Health check & database connection tests
│   ├── reports/                        # Generated Evaluation Graphs & Assets
│   │   ├── emergency/                  # Priority distribution & fake alert charts
│   │   ├── ml/                         # ROC-AUC & PR comparative evaluation curves
│   │   ├── routes/                     # A* detours execution visualization diagrams
│   │   ├── trust/                      # Dynamic trust score convergence plots
│   │   └── xai/                        # Global/local SHAP & LIME explanation figures
│   ├── trust_history/                  # Vehicle Trust Simulation Output Logs
│   │   ├── VEH_CASE_1_NORMAL.json      # Mock evaluation logs for Normal vehicle scenarios
│   │   ├── VEH_CASE_2_SINGLE_ATTACK.json# Mock evaluation logs for Single Anomaly telemetry
│   │   ├── VEH_CASE_3_REPEATED_ATTACK.json# Mock evaluation logs for Repeated threat telemetry
│   │   └── VEH_CASE_4_RECOVERY.json    # Mock evaluation logs for vehicle Trust Recovery epochs
│   ├── pyproject.toml                  # Python package specifications
│   └── alembic.ini                     # Migration engine configuration file
│
├── database/                           # Database Migrations & Schemas
│   ├── alembic/                        # Versioned DB migration schema scripts
│   └── alembic.ini                     # Migration engine configuration file
│
└── dataset/                            # Dataset Directory
    ├── raw/                            # Raw JSON telemetry trace files
    └── processed/                      # Model metadata, scaler.pkl & label mappings
```

---

## 4. Unified System Architecture

### Unified System Block Architecture
```mermaid
graph TD
    A[VANET Fleet Vehicles] 
    --> B[FastAPI API Layer]
    --> C[XGBoost Classifier Model]
    
    C --> D[SHAP / LIME Explainer]
    D --> E[Trust Management Engine]
    
    E --> F[Emergency Preemption Gate]
    F --> G[A* / Dijkstra Routing Solver]
```

### Relational Entity ER Map
```mermaid
erDiagram
    User ||--o{ Vehicle : owns
    Vehicle ||--o{ VehicleMessage : broadcasts
    VehicleMessage ||--|| Prediction : evaluates
    Prediction ||--|| AIExplanation : generates
    Vehicle ||--o{ TrustScore : tracks
    Vehicle ||--o{ DeviceToken : registers
```

---

## 5. Sequence Flows

### Vehicle Detection Sequence Flow
```mermaid
sequenceDiagram
    participant V as Vehicle
    participant API as FastAPI Backend
    participant ML as XGBoost Classifier
    participant TS as Trust Score DB

    V->>API: POST /prediction/analyze (21 BSM Kinematic features)
    API->>ML: Run predict_proba() inference with StandardScaler
    ML-->>API: Malicious/Normal prediction output
    API->>TS: Update dynamic trust composite score
    API-->>V: Return threat prediction, explanation ID, and trust score
```

### AI Explanation Sequence Flow
```mermaid
sequenceDiagram
    participant OP as Operator Client
    participant API as FastAPI Backend
    participant XAI as SHAP / LIME Engine

    OP->>API: GET /xai/explanation/{id}
    API->>XAI: Compute local Shapley values & linear surrogates
    XAI-->>API: Feature weights list + Human reason sentence
    API-->>OP: Returns charts and text explanation
```

### Emergency Preemption Handling
```mermaid
sequenceDiagram
    participant EV as Emergency Vehicle
    participant API as FastAPI Backend
    participant TG as Trust Engine
    participant PM as Priority Manager

    EV->>API: POST /emergency/verify (Token, ID)
    API->>TG: Check trust standing
    TG-->>API: Score >= 80 (Trusted)
    API->>PM: Request preemption status
    PM-->>API: Priority Granted (Critical/High)
    API-->>EV: Dispatch warning alerts
```

### Route Recommendation Detour Flow
```mermaid
sequenceDiagram
    participant EV as Emergency Vehicle
    participant API as FastAPI Backend
    participant RO as Route Optimizer
    participant AM as Accident Manager

    EV->>API: POST /routes/recommend (Source, Target)
    API->>AM: Check blocked segments
    AM-->>API: Accident active on ROAD_BC
    API->>RO: Calculate detour route
    RO-->>API: Path A->D->C->F (A* heuristic)
    API-->>EV: Return Recommended detours path
```

---

## 6. Evaluation & Comparative Benchmarks

### Machine Learning Classification Results
Evaluated on authentic public VeReMi Attack 16 (*EventualStop / Position Falsification*) traces (4,000 sampled message pairs, 80/20 stratified split, 21 physical kinematic features):

| Model | Accuracy | Precision | Recall | F1 Score | ROC-AUC | Avg. Precision | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **LightGBM** | **97.8%** | 98.1% | **93.5%** | **95.8%** | **0.997** | **0.993** | Fast histogram tree growth; top recall |
| **CatBoost** | **97.8%** | 99.0% | 92.6% | 95.7% | **0.997** | **0.993** | Symmetric oblivious decision trees |
| **XGBoost** *(Deployed)* | **97.2%** | 97.6% | 92.2% | 94.8% | **0.997** | 0.992 | **Selected for FastAPI serving & mature SHAP support** |
| **Random Forest** | 96.0% | **100.0%** | 85.3% | 92.0% | 0.996 | 0.991 | Bagging baseline; zero false positives |
| **GRU** | 91.2% | **100.0%** | 67.7% | 80.8% | 0.977 | 0.951 | Recurrent benchmark ($T=1$ per-packet tensor, 5 epochs) |
| **LSTM** | 90.2% | **100.0%** | 64.1% | 78.1% | 0.973 | 0.945 | Recurrent benchmark ($T=1$ per-packet tensor, 5 epochs) |

> **Key Observations & Honest Error Analysis:**
> 1. **Boosting Parity:** All three gradient boosting models (LightGBM, CatBoost, XGBoost) demonstrate comparable performance within a 0.6% margin (~5 test samples out of 800).
> 2. **XGBoost Confusion Matrix (583 Normal, 217 Malicious):** 578 true normal (0.9% false alarms), 200 detected attacks, 17 missed attacks.
> 3. **Stationary Vehicles Error Clustering:** All 22 classification errors (5 false alarms + 17 missed attacks) occur exclusively on stationary vehicles reporting near-zero speed:
>    - **Stationary Normal (110 vehicles):** 5 false alarms (95.5% precision on stationary)
>    - **Stationary Attacks (40 vehicles):** 17 missed attacks (57.5% recall on stationary)
>    - **Moving Vehicles (650 vehicles):** **0 errors (100% Accuracy on moving fleet)**
> 4. **SHAP Feature Importance:** Physical displacement (`delta_pos_magnitude`, mean abs SHAP = 5.83) strongly dominates decisions, followed by `speed_mag2` (0.89), dead-reckoning residual `pos_residual` (0.87), and speed delta `delta_spd_magnitude` (0.54). Reporting positive speed while displacement remains zero drives predictions strongly towards the malicious class (+2 to +3 log-odds).

### Path Routing & Detour Execution Benchmarks
*   **Primary Path Routing Engine:** Dijkstra's algorithm computes the active recommended detour path.
*   **A* Heuristic Admissibility:** The spatial Euclidean distance heuristic is scaled by the distance cost coefficient (`WEIGHT_DISTANCE = 0.40`) to ensure strict admissibility ($h(u, v) \le h^*(u, v)$) across all 30 network node pairs.
*   **Warm Execution Latency (6-Node Grid, 2,000 Iterations Median):**
    *   **Dijkstra's Pathfinder:** `~5.3 µs`
    *   **A* Pathfinder:** `~4.8 µs` (~1.1x speedup on small localized road network)

### Dynamic Trust Engine Dynamics
*   **Trust Scale & Status Mapping:** Continuous score from 0.0 to 100.0 (`INITIAL_TRUST = 100.0`).
    *   $\ge 80.0$: **Trusted Vehicle**
    *   $40.0 - 79.9$: **Suspicious Vehicle**
    *   $< 40.0$: **Untrusted Vehicle**
*   **Composite Formula:**
    $$\text{Trust} = 0.40 \times \text{Direct} + 0.30 \times \text{History} + 0.20 \times \text{Communication} + 0.10 \times \text{XAI}$$
*   **Rapid Normal Recovery Dynamics:** When clean messages resume, Direct, Communication, and XAI components reset to 100.0 ($40 + 20 + 10 = 70.0$ baseline), producing rapid recovery:
    $$\text{Composite} = 0.30 \times (\text{Previous} + 2.0) + 70.0$$
    *(e.g., a suspicious vehicle at 57.5 recovers to 87.85 on the first normal packet; repeated attack scenario `VEH_CASE_3` bottoms out at 34.5 before recovering to 80.95).*

### Emergency Vehicle Priority & Authentication
*   **Simulated Authentication:** Deterministic authorization token verification (`AUTH_EMERGENCY_<TYPE>_<vehicle_id>`) with digital identity length check.
*   **Preemption Gate:** Vehicles with trust $< 40.0$ fail verification as suspicious claims; a 50-point penalty is calculated and dispatched via notifications.
*   **Composite Priority Formula:**
    $$\text{Priority Score} = 0.40 \times \text{Vehicle Type} + 0.30 \times \text{Trust Score} + 0.20 \times \text{Accident Severity} + 0.10 \times \text{Traffic Conditions}$$

### Known Architectural Limitations & Security Defense Analysis
1. **Trust Poisoning Vulnerability (Absence of IEEE 1609.2 Cryptographic Frame Signing):**
   * *Observation:* In open V2X broadcast architectures without hardware HSM or IEEE 1609.2 PKI digital signatures, an attacker can broadcast fake emergency claims (`/emergency/verify`) using an arbitrary victim vehicle ID.
   * *Impact:* A single spoofed fake claim drops a fresh victim vehicle's trust score to **55.0**, and subsequent fake claims bottom out at the **40.0** floor (the maximum history penalty bound).
   * *Defense / Mitigation:* In production C-V2X (3GPP Rel 14/15) and DSRC implementations, emergency frames require asymmetric ECDSA digital signatures signed by a certified SCMS (Security Credential Management System) Certificate Authority, ensuring unauthenticated or spoofed frames are dropped at Layer 2/3 before ingestion by the trust engine.
2. **Dynamic Routing Vehicle-Type Weighting & Traffic Bypass Detection:**
   * Detour route optimization incorporates `vehicle_type` into edge cost evaluation, granting emergency vehicles (e.g. Ambulance, Fire Brigade) corridor speed clearance and reduced congestion cost penalties.
   * Path reason generation dynamically identifies network segments with $\ge 70\%$ traffic density that were bypassed (e.g., bypassing `ROAD_BC` at 80% density via path `A -> D -> C -> F`), completely separating accident blockages from traffic congestion notifications.

---

## 7. Setup & Offline Execution Guide

### Prerequisite Environment
*   **Python**: 3.11+ (Tested on Python 3.13)
*   **Flutter SDK**: 3.22+ (Tested on Flutter 3.41.7)
*   **Google Chrome** or **Windows Visual Studio Build Tools** (for desktop/web target)

---

### Backend Server Execution
1.  Navigate into the `backend/` directory:
    ```bash
    cd backend
    ```
2.  Start the FastAPI Server with live auto-reload:
    ```bash
    uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
    ```
3.  Open interactive API documentation in your browser:
    *   Swagger UI: `http://127.0.0.1:8000/docs`
    *   ReDoc: `http://127.0.0.1:8000/redoc`

---

### Machine Learning Training & Model Evaluation (Google Colab)
All machine learning model training, comparative benchmarking (XGBoost, CatBoost, LightGBM, Random Forest, LSTM, GRU), evaluation metrics (Accuracy %, F1 %, ROC/PR curves), and Explainable AI (SHAP) are conducted interactively in **Google Colab**:
* **Interactive Notebook:** [`VANET_Misbehavior_Detection_Colab.ipynb`](VANET_Misbehavior_Detection_Colab.ipynb)
* **Outputs Generated:** `best_model.joblib` and `scaler.pkl` (exported directly to `backend/models/` for FastAPI serving)

---

### Backend Services & Simulation Pipelines
The FastAPI backend serves the trained model (`backend/models/best_model.joblib`) via the `/prediction/analyze` endpoint (enforcing exact 21-feature input schemas and `StandardScaler` transformations) along with modular simulation scripts:

| Task | Command (Run inside `backend/`) | Outputs Generated |
| :--- | :--- | :--- |
| **1. Simulate Dynamic Trust** | `python scripts/simulate_trust.py` | `backend/trust_history/`, `backend/reports/trust/fleet_rankings.png` |
| **2. Test Emergency Priority** | `python scripts/simulate_emergency.py` | `backend/reports/emergency/priority_distribution.png` |
| **3. Run A* Detour Routing** | `python scripts/simulate_routing.py` | `backend/reports/routes/accident_detour_comparison.png` |
| **4. Real-Time FCM Alerts** | `python scripts/simulate_notifications.py` | Push notification payloads & simulation logs |

---

### Executing Automated Test Suites

#### 1. Backend Test Suite (FastAPI, ML, Trust, Routing)
```bash
cd backend
python -m pytest
```
*Executes all 20 test cases across `test_api.py`, `test_backend.py`, and `test_health.py`.*

#### 2. Frontend Test Suite (Flutter Widget & Riverpod State)
```bash
cd frontend
flutter test
```
*Executes all 4 Flutter unit and widget tests.*

---

### Flutter Client Application Setup
1.  Navigate into the `frontend/` directory:
    ```bash
    cd frontend
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the application on your preferred platform:
    *   **Windows Desktop**:
        ```bash
        flutter run -d windows
        ```
    *   **Web Browser (Chrome)**:
        ```bash
        flutter run -d chrome
        ```

> **Note on Client Presentation:** The Flutter client features a self-contained interactive state provider (`dashboard_provider.dart` with vehicles `V-101` to `V-404`) allowing standalone UI evaluation and offline defense presentations.

---

## 8. REST API Endpoints Overview

| Category | Method | Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **Misbehavior ML** | `POST` | `/api/v1/prediction/analyze` | Evaluates 21 BSM kinematic features via StandardScaler + XGBoost |
| **Explainable AI** | `GET` | `/api/v1/xai/explanation/{id}` | Retrieves local SHAP feature weights, LIME surrogates, and natural language reasons |
| **Trust Management** | `POST` | `/api/v1/trust/update` | Calculates dynamic trust composite score and updates penalty standing |
| **Trust Management** | `GET` | `/api/v1/trust/{vehicle_id}` | Retrieves vehicle trust score history, attack logs, and classification status |
| **Emergency Priority** | `POST` | `/api/v1/emergency/register` | Registers emergency fleet vehicle (Ambulance, Police, Fire, Rescue) |
| **Emergency Priority** | `POST` | `/api/v1/emergency/verify` | Authenticates emergency claims and checks vehicle trust standing |
| **Emergency Priority** | `POST` | `/api/v1/emergency/alert` | Generates prioritized alert dispatch with dynamic priority scoring |
| **Route Detour** | `POST` | `/api/v1/routing/accident` | Registers traffic hazard / accident blockage on road network |
| **Route Detour** | `POST` | `/api/v1/routing/recommend` | Computes congestion/accident-avoiding detour using Dijkstra pathfinder |
| **Fleet Reports** | `GET` | `/api/v1/reports/trust` | Aggregated security trust distributions and vehicle rankings |
| **Notifications** | `POST` | `/api/v1/notifications/register-token` | Registers client FCM device tokens for real-time mobile push alerts |
