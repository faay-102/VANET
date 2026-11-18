"""
VANET Misbehavior Detection - Dataset Pipeline
----------------------------------------------
NOTE: All dataset preprocessing, 26-feature engineering, stratified
80/20 Train-Test splitting, model training, and evaluation are executed
directly in Google Colab:
    -> 'colab/VANET_Misbehavior_Detection_Colab.ipynb'

The trained model binary ('best_model.joblib') generated on Colab is
exported and placed under 'backend/models/best_model.joblib' for the
FastAPI backend.
"""

def main():
    print("\n" + "="*70)
    print("VANET MISBEHAVIOR DETECTION - DATASET PIPELINE")
    print("="*70)
    print("All preprocessing, train-test splitting, and model training are executed on Google Colab:")
    print("Path: colab/VANET_Misbehavior_Detection_Colab.ipynb")
    print("="*70 + "\n")

if __name__ == "__main__":
    main()
