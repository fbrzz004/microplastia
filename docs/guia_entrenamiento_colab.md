# Entrenamiento del modelo en Google Colab (GPU T4)

Guía para generar el `best.pt` real del detector de microplásticos (YOLOv8n),
evaluarlo sobre el split de prueba y colocarlo en el backend.

- **Dataset:** Microplastic Detection Dataset v6 — University of Alabama (Roboflow), licencia MIT.
- **Clases (4):** `dirt`, `fiber`, `fragment`, `pellet`.
- **Imágenes:** 1680 → 1176 train / 336 valid / 168 test (formato YOLO).
- **Enlace Drive del dataset:** https://drive.google.com/file/d/1GiALvFUCfDtA-Gilqm3HF_NaERhOjVKn/view?usp=sharing

> Ejecuta las celdas en orden. Duración aproximada en T4: ~25–40 min para 100 épocas.

---

## Celda 0 — Activar GPU

`Entorno de ejecución → Cambiar tipo de entorno de ejecución → T4 GPU`, y luego:

```python
!nvidia-smi
```

## Celda 1 — Montar Google Drive (para guardar resultados)

```python
from google.colab import drive
drive.mount('/content/drive')
```

## Celda 2 — Descargar y descomprimir el dataset

```python
import os, zipfile

os.makedirs('/content/dataset_microplasticos', exist_ok=True)

# Opción A: descarga directa desde Drive
# (si el archivo no es público, súbelo a tu Drive y usa la Opción B)
!pip -q install gdown
!gdown --id 1GiALvFUCfDtA-Gilqm3HF_NaERhOjVKn -O /content/dataset_test.zip

# Opción B (si la descarga falla): subirlo manualmente
# from google.colab import files
# files.upload()  # elige dataset_test.zip

with zipfile.ZipFile('/content/dataset_test.zip') as z:
    z.extractall('/content/dataset_microplasticos')

print(os.listdir('/content/dataset_microplasticos'))
```

## Celda 3 — Verificar el dataset

```python
import yaml
with open('/content/dataset_microplasticos/data.yaml') as f:
    cfg = yaml.safe_load(f)
print(cfg['names'], '| nc =', cfg['nc'])

for split in ('train', 'valid', 'test'):
    imgs = [p for p in os.listdir(f'/content/dataset_microplasticos/{split}/images') if p.lower().endswith(('.jpg', '.jpeg', '.png'))]
    print(f'{split:6s}: {len(imgs)} imágenes')
```

Debe mostrar: `['dirt', 'fiber', 'fragment', 'pellet'] | nc = 4` y `1176 / 336 / 168`.

## Celda 4 — Instalar Ultralytics y entrenar

Los resultados se guardan en Drive para no perderlos si se corta la sesión.
Estos hiperparámetros reproducen la corrida reportada (640 px).

```python
!pip -q install -U ultralytics

from ultralytics import YOLO

model = YOLO('yolov8n.pt')   # base preentrenada en COCO

model.train(
    data='/content/dataset_microplasticos/data.yaml',
    epochs=100,
    imgsz=640,
    batch=16,
    device=0,                 # GPU T4
    patience=25,              # early stopping
    cos_lr=True,
    plots=True,               # guarda curvas, matriz de confusión, etc.
    seed=0,
    project='/content/drive/MyDrive/microplastia_runs',
    name='microplastics_v6',
    exist_ok=True,
)
print('Entrenamiento finalizado.')
```

## Celda 5 — Evaluar en el split de prueba (métricas)

```python
from ultralytics import YOLO

WEIGHTS = '/content/drive/MyDrive/microplastia_runs/microplastics_v6/weights/best.pt'
model = YOLO(WEIGHTS)

metrics = model.val(
    data='/content/dataset_microplasticos/data.yaml',
    split='test',
    imgsz=640,
    device=0,
    plots=True,
)

print(f'Precisión (P)   : {metrics.box.mp:.4f}')
print(f'Recall (R)      : {metrics.box.mr:.4f}')
print(f'mAP@50          : {metrics.box.map50:.4f}')
print(f'mAP@50-95       : {metrics.box.map:.4f}')

# Métricas por clase
for i, c in enumerate(metrics.names.values()):
    print(f'  {c:9s} P={metrics.box.p[i]:.4f}  R={metrics.box.r[i]:.4f}  mAP@50={metrics.box.ap50[i]:.4f}  mAP@50-95={metrics.box.ap[i]:.4f}')
```

> Copia estos números: son los que reemplazan los `[[pendiente]]` en
> `docs/informe/4.1_modelo_deteccion.md`.

## Celda 6 — Descargar `best.pt`

```python
from google.colab import files
files.download('/content/drive/MyDrive/microplastia_runs/microplastics_v6/weights/best.pt')
```

Verifica que el archivo descargado **no** sea el `yolov8n.pt` de COCO:

```python
import hashlib
print(hashlib.md5(open('/content/drive/MyDrive/microplastia_runs/microplastics_v6/weights/best.pt','rb').read()).hexdigest())
# NO debe ser 95a2449609c73cd69a072b09daaff0cc (ese es el yolov8n stock)
```

---

## Integración en el backend local

```bash
# 1. Coloca el modelo descargado
cp ~/Descargas/best.pt backend/weights/best.pt

# 2. Reinicia el backend (desde backend/)
source venv/bin/activate
uvicorn app.main:app --reload
```

Prueba rápida del endpoint real:

```bash
curl -F "file=@ruta/a/una_imagen.jpg" http://localhost:8000/api/v1/analyze
```

La respuesta debe traer detecciones con clases `fibra`, `fragmento`, `gránulo`
o `partícula orgánica` (mapeadas desde `fiber`, `fragment`, `pellet`, `dirt`),
y una imagen anotada en `static/detections/`.

---

## Alternativa: script local (ya incluido en el repo)

Si prefieres entrenar sin Colab, el repositorio trae `backend/scripts/train_model.py`:

```bash
cd backend
./venv/bin/python scripts/train_model.py --epochs 60 --imgsz 512 --batch 16 --device cpu
```

En CPU tarda ~5 h; en Colab (GPU) es cuestión de minutos.
