"""Entrena (fine-tuning) YOLOv8n sobre el dataset de microplásticos y exporta best.pt.

Dataset (Roboflow v6, University of Alabama): clases ['dirt', 'fiber', 'fragment', 'pellet'].
Estructura esperada:
    backend/datasets/microplastics/
        data.yaml
        train/{images,labels}/
        valid/{images,labels}/
        test/{images,labels}/

Uso típico (CPU, pocas épocas):
    python scripts/train_model.py --epochs 60 --imgsz 512 --batch 16
Uso en Colab (GPU):
    python scripts/train_model.py --epochs 100 --imgsz 640 --batch 16 --device 0

Al terminar copia el mejor peso a backend/weights/best.pt (salvo --no-copy).
"""

import argparse
import shutil
from pathlib import Path

from ultralytics import YOLO

BACKEND_DIR = Path(__file__).resolve().parent.parent
DEFAULT_DATA = BACKEND_DIR / "datasets" / "microplastics" / "data.yaml"
DEFAULT_WEIGHTS = BACKEND_DIR / "weights" / "best.pt"


def main() -> int:
    parser = argparse.ArgumentParser(description="Entrenamiento YOLOv8n - MicroplastIA")
    parser.add_argument("--data", default=str(DEFAULT_DATA))
    parser.add_argument("--base", default="yolov8n.pt", help="Pesos base (preentrenados COCO).")
    parser.add_argument("--epochs", type=int, default=60)
    parser.add_argument("--imgsz", type=int, default=512)
    parser.add_argument("--batch", type=int, default=16)
    parser.add_argument("--workers", type=int, default=8)
    parser.add_argument("--patience", type=int, default=20, help="Early stopping.")
    parser.add_argument("--device", default=None, help="'0' para GPU, 'cpu' para CPU.")
    parser.add_argument("--project", default=str(BACKEND_DIR / "runs"))
    parser.add_argument("--name", default="microplastics_v6")
    parser.add_argument(
        "--no-copy",
        action="store_true",
        help="No copiar el best.pt resultante a backend/weights/.",
    )
    args = parser.parse_args()

    data = Path(args.data)
    if not data.exists():
        print(
            f"[ERROR] No se encontró el dataset en {data}.\n"
            "        Descárgalo (Roboflow v6) y colócalo en backend/datasets/microplastics/.",
        )
        return 1

    model = YOLO(args.base)
    model.train(
        data=str(data),
        epochs=args.epochs,
        imgsz=args.imgsz,
        batch=args.batch,
        workers=args.workers,
        patience=args.patience,
        device=args.device,
        project=args.project,
        name=args.name,
        exist_ok=True,
        cache=True,
        cos_lr=True,
        plots=True,
        seed=0,
    )

    best = Path(args.project) / "detect" / args.name / "weights" / "best.pt"
    if not best.exists():
        # Distintas versiones de ultralytics guardan en rutas ligeramente distintas.
        matches = list(Path(args.project).rglob("best.pt"))
        if not matches:
            print("[ERROR] No se generó best.pt. Revisa la salida de entrenamiento.")
            return 1
        best = matches[-1]

    print(f"\nMejor modelo: {best}")
    if not args.no_copy:
        DEFAULT_WEIGHTS.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(best, DEFAULT_WEIGHTS)
        print(f"Copiado a: {DEFAULT_WEIGHTS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
