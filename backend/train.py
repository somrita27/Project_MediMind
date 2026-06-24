"""
MediMind — Disease Predictor Training Script
Author : Srijon Ghosh

Run:
    python backend/train.py

Outputs:
    backend/models/disease_model.pkl
    backend/output/diseases.json
"""

import warnings
warnings.filterwarnings("ignore")

import os
import json
import joblib
import numpy as np
import pandas as pd

from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier

# ============================================================================
# 1. Create Required Folders
# ============================================================================

os.makedirs("backend/models", exist_ok=True)
os.makedirs("backend/output", exist_ok=True)

# ============================================================================
# 2. Load Dataset
# ============================================================================

print("Loading dataset...")

df = pd.read_csv("backend/data/merged_disease_dataset.csv")

print(f"  Loaded {len(df)} disease records")
print(f"  Columns: {df.columns.tolist()}")

X = df["Key Symptoms"].fillna("").astype(str).tolist()
y = df["Disease"].fillna("").astype(str).tolist()

# ============================================================================
# 3. Build Model Pipeline
# ============================================================================

print("\nBuilding model pipeline...")

model = Pipeline([
    (
        "tfidf",
        TfidfVectorizer(
            ngram_range=(1, 2),
            max_features=5000,
            lowercase=True,
            strip_accents="unicode",
            token_pattern=r"[a-zA-Z][a-zA-Z]+",
        ),
    ),
    (
        "rf",
        RandomForestClassifier(
            n_estimators=300,
            max_depth=None,
            min_samples_split=2,
            random_state=42,
            n_jobs=-1,
        ),
    ),
])

# ============================================================================
# 4. Train Model
# ============================================================================

print("Training...")

model.fit(X, y)

train_acc = np.mean(
    np.array(model.predict(X)) == np.array(y)
)

print(f"  Train accuracy: {train_acc * 100:.1f}%")

# ============================================================================
# 5. Sanity Tests
# ============================================================================

print("\nQuick sanity tests (top-3 predictions):")

tests = [
    "fever headache body aches chills cough runny nose",
    "persistent sadness no energy sleep problems hopelessness",
    "severe chest pain shortness of breath sweating left arm pain",
    "burning stomach pain after eating nausea bloating",
    "frequent urination excessive thirst blurred vision fatigue",
    "stiff neck high fever sudden severe headache photophobia",
    "itchy circular ring-shaped rash scaly skin hair loss",
]

classes = model.classes_

for test in tests:

    proba = model.predict_proba([test])[0]

    top3_idx = np.argsort(proba)[::-1][:3]

    print(f"\nSymptoms: '{test}'")

    for i in top3_idx:
        bar = "█" * int(proba[i] * 40)

        print(
            f"  {classes[i]:<35} "
            f"{proba[i] * 100:5.1f}% {bar}"
        )

# ============================================================================
# 6. Save Model
# ============================================================================

MODEL_PATH = "backend/models/disease_model.pkl"

joblib.dump(model, MODEL_PATH)

print(f"\n✅ Model saved → {MODEL_PATH}")

print(
    f"   Vocabulary size : "
    f"{len(model.named_steps['tfidf'].vocabulary_)}"
)

print(
    f"   Number of trees : "
    f"{model.named_steps['rf'].n_estimators}"
)

print(
    f"   Classes         : "
    f"{len(classes)} diseases"
)

# ============================================================================
# 7. Export Disease Database to JSON
# ============================================================================

records = []

for _, row in df.iterrows():

    record = {
        "category": str(row.get("Category", "")),
        "disease": str(row.get("Disease", "")),
        "symptoms": str(row.get("Key Symptoms", "")),
        "medicine": str(row.get("Primary Medicine(s)", "")),
        "frequency": str(row.get("Frequency per Day", "")),
        "time": str(row.get("Time", "")),
        "duration_days": str(row.get("Duration(Days)", "")),
        "precautions": str(row.get("Precautions / Notes", "")),
    }

    records.append(record)

JSON_PATH = "backend/output/diseases.json"

with open(JSON_PATH, "w", encoding="utf-8") as f:
    json.dump(
        records,
        f,
        indent=2,
        ensure_ascii=False
    )

print(f"✅ Disease database exported → {JSON_PATH}")

# ============================================================================
# 8. Finished
# ============================================================================

print("\n🎉 Training completed successfully!")
print("   Model  : backend/models/disease_model.pkl")
print("   Dataset: backend/output/diseases.json")