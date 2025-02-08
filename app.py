from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from PIL import Image
import io
import os
import torch
from torchvision import models, transforms
import numpy as np
from fastapi.middleware.cors import CORSMiddleware

# Initialisation de l'application FastAPI
app = FastAPI()

# CORS Middleware Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Autoriser toutes les origines (ou spécifiez votre origine)
    allow_credentials=True,
    allow_methods=["*"],  # Autoriser toutes les méthodes HTTP (GET, POST, etc.)
    allow_headers=["*"],  # Autoriser tous les en-têtes
)

# Charger EfficientNet-B0 avec les poids pré-entrainés
model = models.efficientnet_b0(weights='IMAGENET1K_V1')  # Charger les poids pré-entrainés sur ImageNet
model.classifier[1] = torch.nn.Linear(in_features=1280, out_features=2)  # Modifier la dernière couche pour 2 classes

# Charger les poids personnalisés sur le CPU
model.load_state_dict(torch.load("best_model.pth", map_location=torch.device('cpu')))
model.eval()  # Passer en mode évaluation

# Transformation d'image (prétraitement pour le modèle EfficientNet)
transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

# Fonction pour prédire l'image avec le modèle EfficientNet-B0
def predict_image(image: Image.Image):
    # Appliquer les transformations nécessaires
    image_tensor = transform(image).unsqueeze(0)  # Ajouter une dimension de batch
    
    # Effectuer la prédiction
    with torch.no_grad():
        outputs = model(image_tensor)
    
    # Obtenir la classe prédite
    _, predicted_class = torch.max(outputs, 1)
    
    return predicted_class.item()

# Route pour recevoir l'image et renvoyer la prédiction
@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    try:
        # Lire l'image à partir du fichier téléchargé
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes))
        
        # Appliquer la prédiction
        predicted_class = predict_image(image)
        
        # Retourner le résultat sous forme de réponse JSON
        print(predicted_class)
        return JSONResponse(content={"predicted_class": predicted_class}, status_code=200)
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return JSONResponse(content={"error": str(e)}, status_code=400)
