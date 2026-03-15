# THIS IS THE BOAT 


## création de l'environnement virtuel python (en 3.10): 
```bash
py -3.10 -m venv python

cd python
Scripts/activate

pip install -r requirements.txt
```

## entrainement du modèle : 

lancer l'environnement virtuel python, puis exécuter la commande suivante :
```bash
py .\stable_baselines3_example.py --onnx_export_path=model.onnx --timesteps=10000
```
pour entrainer le modèle et l'exporter au format onnx, sur 10 000 étapes.

ensuite, lancer le projet configuré correctement dans godot.
-> le modèle entrainé sera exporté dans python/model.onnx

## utilisation du modèle dans godot :

copier le fichier model.onnx dans le dossier res:// du projet godot, puis lancer le projet en donnant le chemin du modèle en argument : Onnx Model = "model.onnx" (si le modèle est dans res://)
