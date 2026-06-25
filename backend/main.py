"""
MediMind — FastAPI Backend
Author : Srijon Ghosh

Endpoints:
    POST /predict          — symptom text → disease + medicine + schedule
    GET  /diseases         — list all diseases in the knowledge base
    GET  /disease/{name}   — look up a disease by exact name
    GET  /health           — server health check

Run:
    uvicorn main:app --reload

Docs:
    http://127.0.0.1:8000/docs
"""

from __future__ import annotations
import re
import json
import warnings
from pathlib import Path

warnings.filterwarnings("ignore")

import numpy as np
import pandas as pd
import joblib
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Constants
DATA_PATH  = Path("backend/data/merged_disease_dataset.csv")
MODEL_PATH = Path("backend/models/disease_model.pkl")
JSON_PATH  = Path("backend/output/diseases.json")

DISCLAIMER = (
    "⚠️  These suggestions are for informational purposes only. "
    "Always consult a qualified doctor before taking any medication."
)

# Time string → list of schedule slots
TIME_MAP = {
    "early morning":  "06:30",
    "morning":        "08:00",
    "afternoon":      "13:00",
    "evening":        "18:00",
    "before bed":     "22:00",
    "night, before bed": "22:00",
    "night":          "21:00",
}

def parse_schedule(raw: str) -> list[dict]:
    raw_lower = str(raw).lower()
    slots: list[dict] = []
    for label, t in TIME_MAP.items():
        if label in raw_lower and not any(s["time"] == t for s in slots):
            slots.append({"label": label.title(), "time": t})
    if not slots:
        slots.append({"label": "Morning", "time": "08:00"})
    return sorted(slots, key=lambda x: x["time"])


def parse_duration(raw: str) -> dict:
    raw = str(raw).strip()
    if any(k in raw.lower() for k in ["lifelong", "long-term", "lifetime", "ongoing"]):
        return {"days": None, "label": raw}
    nums = re.findall(r"\d+", raw)
    return {"days": int(nums[-1]), "label": raw} if nums else {"days": None, "label": raw}


#  Load assets at startup
print("Loading model and dataset...")
model = joblib.load(MODEL_PATH)
df    = pd.read_csv(DATA_PATH)

# Build a fast disease → row dict
disease_db: dict[str, dict] = {}
for _, row in df.iterrows():
    disease_db[row["Disease"]] = {
        "id":          int(row["#"]),
        "category":    str(row["Category"]).strip(),
        "disease":     str(row["Disease"]).strip(),
        "symptoms":    str(row["Key Symptoms"]).strip(),
        "medicine":    str(row["Primary Medicine(s)"]).strip(),
        "frequency":   str(row["Frequency per Day"]).strip(),
        "schedule":    parse_schedule(row["Time"]),
        "duration":    parse_duration(row["Duration(Days)"]),
        "precautions": str(row["Precautions / Notes"]).strip(),
    }

# Load pre-built JSON (used for /diseases list)
with open(JSON_PATH, "r", encoding="utf-8") as f:
    diseases_list = json.load(f)

CLASSES = model.classes_
print(f"✅ Ready — {len(disease_db)} diseases, {len(CLASSES)} classes")


# FastAPI app
app = FastAPI(
    title="MediMind API",
    description="AI-powered symptom analysis and medicine scheduling",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # restrict in production
    allow_methods=["*"],
    allow_headers=["*"],
)


# Schemas
class SymptomInput(BaseModel):
    symptoms: str

    class Config:
        json_schema_extra = {
            "example": {"symptoms": "fever, headache, body aches, chills, cough"}
        }


class ScheduleSlot(BaseModel):
    label: str   # "Morning", "Afternoon", "Night"
    time:  str   # "08:00"


class DurationInfo(BaseModel):
    days:  int | None
    label: str


class PredictionResponse(BaseModel):
    disease:    str
    category:   str
    confidence: float          # top-1 probability (0–1)
    top3: list[dict]           # [{disease, confidence}, ...]
    medicine:   str
    frequency:  str
    schedule:   list[ScheduleSlot]
    duration:   DurationInfo
    precautions: str
    disclaimer: str


#  Endpoints 

@app.get("/health")
def health():
    return {"status": "ok", "diseases_loaded": len(disease_db)}


@app.get("/diseases")
def list_diseases():
    """Return all 200 diseases with full details."""
    return {"count": len(diseases_list), "diseases": diseases_list}


@app.get("/disease/{name}")
def get_disease(name: str):
    """Look up a disease by exact name (case-sensitive)."""
    if name not in disease_db:
        raise HTTPException(404, detail=f"Disease '{name}' not found in knowledge base.")
    return disease_db[name]


@app.post("/predict", response_model=PredictionResponse)
def predict(data: SymptomInput):
    """
    Main endpoint.
    Send user's symptom text → get disease prediction + full medicine schedule.

    Flutter calls this after the user types (or speaks) their symptoms.
    """
    if not data.symptoms.strip():
        raise HTTPException(400, detail="Symptoms text cannot be empty.")

    #  ML prediction
    proba    = model.predict_proba([data.symptoms])[0]
    top3_idx = np.argsort(proba)[::-1][:3]

    top_disease    = CLASSES[top3_idx[0]]
    top_confidence = float(proba[top3_idx[0]])

    top3_list = [
        {"disease": CLASSES[i], "confidence": round(float(proba[i]), 4)}
        for i in top3_idx
    ]

    # Knowledge base lookup
    if top_disease not in disease_db:
        raise HTTPException(500, detail=f"Predicted disease '{top_disease}' missing from KB.")

    info = disease_db[top_disease]

    return PredictionResponse(
        disease     = info["disease"],
        category    = info["category"],
        confidence  = round(top_confidence, 4),
        top3        = top3_list,
        medicine    = info["medicine"],
        frequency   = info["frequency"],
        schedule    = [ScheduleSlot(**s) for s in info["schedule"]],
        duration    = DurationInfo(**info["duration"]),
        precautions = info["precautions"],
        disclaimer  = DISCLAIMER,
    )