"""Evalúa el modelo de detección (best.pt) sobre un dataset en formato YOLO.

Uso:
    python scripts/evaluate_model.py --data ruta/al/dataset.yaml
    python scripts/evaluate_model.py --data dataset.yaml --split test

Requiere un dataset con la estructura estándar de Ultralytics:
    dataset/
      images/{train,val,test}/
      labels/{train,val,test}/
      dataset.yaml   (names, nc, path, train, val, test)

Si no se indica --data, se busca `data.yaml`/`dataset.yaml` en la carpeta
`datasets/` del backend. El resultado (mAP50, mAP50-95, precisión, recall)
se imprime en consola y se guarda en `runs/detect/val/`.
"""

import argparse
import sys
from pathlib import Path

from ultralytics import YOLO

BACKEND_DIR = Path(__file__).resolve().parent.parent


def _find_default_data() -> Path | None:
    for candidate in (
        "datasets/microplastics/data.yaml",
        "datasets/dataset.yaml",
        "datasets/data.yaml",
    ):
        path = BACKEND_DIR / candidate
        if path.exists():
            return path
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Evaluación del modelo YOLOv8n de MicroplastIA")
    parser.add_argument(
        "--weights",
        default=str(BACKEND_DIR / "weights" / "best.pt"),
        help="Ruta a los pesos del modelo (por defecto weights/best.pt).",
    )
    parser.add_argument(
        "--data",
        default=None,
        help="Ruta al dataset.yaml con la definición de clases y splits.",
    )
    parser.add_argument(
        "--split",
        default="val",
        choices=["train", "val", "test"],
        help="Split a evaluar (por defecto val).",
    )
    parser.add_argument("--imgsz", type=int, default=640)
    parser.add_argument("--conf", type=float, default=0.25)
    args = parser.parse_args()

    weights = Path(args.weights)
    if not weights.exists():
        print(f"[ERROR] No se encontró el modelo en {weights}", file=sys.stderr)
        return 1

    data = Path(args.data) if args.data else _find_default_data()
    if data is None or not data.exists():
        print(
            "[ERROR] No se encontró el dataset. Pasa --data ruta/dataset.yaml\n"
            "        o coloca dataset.yaml dentro de backend/datasets/.",
            file=sys.stderr,
        )
        return 1

    print(f"Modelo : {weights}")
    print(f"Dataset: {data} (split={args.split})")

    model = YOLO(str(weights))
    metrics = model.val(
        data=str(data),
        split=args.split,
        imgsz=args.imgsz,
        conf=args.conf,
        verbose=True,
    )

    box = metrics.box
    print("\n=== Resultados ===")
    print(f"Precisión (P) : {box.mp:.4f}")
    print(f"Recall (R)    : {box.mr:.4f}")
    print(f"mAP50         : {box.map50:.4f}")
    print(f"mAP50-95      : {box.map:.4f}")

    # Desglose por clase
    names = metrics.names
    print("\n=== Por clase ===")
    print(f"{'clase':<12}{'P':>8}{'R':>8}{'mAP50':>9}{'mAP50-95':>11}")
    for i, cls_name in sorted(names.items()):
        print(
            f"{cls_name:<12}{box.p[i]:>8.4f}{box.r[i]:>8.4f}"
            f"{box.ap50[i]:>9.4f}{box.ap[i]:>11.4f}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
