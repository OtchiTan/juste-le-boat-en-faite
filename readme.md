# THIS IS THE BOAT 

!!!! On a besoin de GODOT 4.6.+ en DOTNET (sinon pas d'IA)

## création de l'environnement virtuel python (en 3.10): 
```bash
cd python

py -3.10 -m venv venv

venv/Scripts/activate

pip install -r requirements.txt
```

## entrainement du modèle : 

lancer l'environnement virtuel python, puis exécuter la commande suivante (depuis le dossier python) :
```bash
py .\stable_baselines3_example.py --onnx_export_path=model.onnx --timesteps=10000
```
pour entrainer le modèle et l'exporter au format onnx, sur 10 000 étapes.

ensuite, lancer le projet configuré correctement dans godot (en passant le noeud sync du projet en mode Training)
-> le modèle entrainé sera exporté dans python/model.onnx

## utilisation du modèle dans godot :

copier le chemin relatif du modèle onnx (python/model.onnx) et le coller dans le champ "Model Path" du noeud "Sync" du projet godot.
