Readme principal : [Main Readme](../readme.md)


## création de l'environnement virtuel python (version 3.10): 
```bash
cd python

py -3.10 -m venv venv

venv/Scripts/activate

pip install -r requirements.txt
```

## entrainement du modèle : 

lancer l'environnement virtuel python, puis exécuter la commande suivante (depuis le dossier python) :
```bash
py .\stable_baselines3_example.py --onnx_export_path "model.onnx" --timesteps=30000
```


Pour lancer un entrainement avec sauvegardes intermédiaires : 
```bash
py stable_baselines3_example.py --timesteps=500000 --save_checkpoint_frequency=50000 --save_model_path "model_zip" --onnx_export_path "model.onnx"
```

Pour reprendre un entrainement à partir d'un modèle déjà entrainé :
```bash
py stable_baselines3_example.py --timesteps=1000000 --resume_model_path "../model_to_resume.zip" --onnx_export_path "model.onnx"
```

Pour entrainer le modèle à partir d'un exécutable (en lançant 8 instances en vitesse x32)
```bash 
py stable_baselines3_example.py --timesteps=100000000--save_checkpoint_frequency=2000000 --save_model_path "../save_file" --speedup 32 --n_parallel 8 --viz  --env_path="../build_boat/build.exe" --experiment_name="name_of_experiment"
```
ensuite, lancer le projet configuré correctement dans godot (en passant le noeud sync du projet en mode Training)
-> le modèle entrainé sera exporté dans python/model.onnx


## utilisation du modèle dans godot :

copier le chemin relatif du modèle onnx (python/model.onnx) et le coller dans le champ "Model Path" du noeud "Sync" du projet godot.
