import io
import re

import cv2
import numpy as np
from PIL import Image
from pillow_heif import register_heif_opener

from app.core.config import settings


register_heif_opener()


# ==========================================================
# FORMATOS PERMITIDOS
# ==========================================================

ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",

    # Algunos clientes móviles pueden enviar
    # archivos sin un MIME preciso.
    "application/octet-stream",
    "binary/octet-stream",
}


# ==========================================================
# LÍMITES DE IMAGEN
# ==========================================================

MAX_IMAGE_WIDTH = 12000
MAX_IMAGE_HEIGHT = 12000
MAX_IMAGE_PIXELS = 40_000_000


# ==========================================================
# SAMPLE ID
# ==========================================================

SAMPLE_ID_PATTERN = re.compile(
    r"^[A-Za-z0-9_-]{1,50}$"
)


class InvalidUploadError(ValueError):
    pass


# ==========================================================
# SAMPLE ID
# ==========================================================

def validate_sample_id(
    sample_id: str | None,
) -> str | None:

    if sample_id is None:
        return None

    sample_id = sample_id.strip()

    if not sample_id:
        return None

    if not SAMPLE_ID_PATTERN.fullmatch(
        sample_id
    ):
        raise InvalidUploadError(
            "El identificador de la muestra "
            "contiene caracteres no permitidos."
        )

    return sample_id


# ==========================================================
# CONTENT TYPE
# ==========================================================

def validate_content_type(
    content_type: str | None,
) -> None:

    if not content_type:
        return

    normalized = (
        content_type
        .strip()
        .lower()
        .split(";")[0]
    )

    if normalized not in ALLOWED_CONTENT_TYPES:

        raise InvalidUploadError(
            "Formato de imagen no permitido. "
            "Usa JPG, JPEG, PNG, WEBP, HEIC o HEIF."
        )


# ==========================================================
# TAMAÑO
# ==========================================================

def validate_image_size(
    image_bytes: bytes,
) -> None:

    if not image_bytes:

        raise InvalidUploadError(
            "El archivo está vacío."
        )

    max_bytes = (
        settings.max_upload_mb
        * 1024
        * 1024
    )

    if len(image_bytes) > max_bytes:

        raise InvalidUploadError(
            f"La imagen supera el tamaño "
            f"máximo permitido "
            f"({settings.max_upload_mb} MB)."
        )


# ==========================================================
# DECODIFICACIÓN CON OPENCV
# ==========================================================

def _decode_with_opencv(
    image_bytes: bytes,
) -> np.ndarray | None:

    try:

        np_buffer = np.frombuffer(
            image_bytes,
            dtype=np.uint8,
        )

        image = cv2.imdecode(
            np_buffer,
            cv2.IMREAD_COLOR,
        )

        return image

    except Exception:

        return None


# ==========================================================
# DECODIFICACIÓN CON PILLOW
# ==========================================================

def _decode_with_pillow(
    image_bytes: bytes,
) -> np.ndarray | None:

    try:

        with Image.open(
            io.BytesIO(
                image_bytes
            )
        ) as pil_image:

            # Normalizamos cualquier modo:
            # RGBA, P, CMYK, etc.
            pil_image = pil_image.convert(
                "RGB"
            )

            image_rgb = np.array(
                pil_image
            )

            # OpenCV/YOLO trabajan normalmente
            # con BGR.
            image_bgr = cv2.cvtColor(
                image_rgb,
                cv2.COLOR_RGB2BGR,
            )

            return image_bgr

    except Exception:

        return None


# ==========================================================
# VALIDAR DIMENSIONES
# ==========================================================

def _validate_dimensions(
    image: np.ndarray,
) -> None:

    if image.ndim < 2:

        raise InvalidUploadError(
            "La imagen no tiene "
            "dimensiones válidas."
        )

    height, width = image.shape[:2]

    if (
        width <= 0
        or height <= 0
    ):

        raise InvalidUploadError(
            "La imagen no tiene "
            "dimensiones válidas."
        )

    if (
        width > MAX_IMAGE_WIDTH
        or height > MAX_IMAGE_HEIGHT
    ):

        raise InvalidUploadError(
            "La resolución de la imagen "
            "es demasiado grande."
        )

    if (
        width * height
        > MAX_IMAGE_PIXELS
    ):

        raise InvalidUploadError(
            "La imagen contiene "
            "demasiados píxeles."
        )


# ==========================================================
# DECODIFICACIÓN Y VALIDACIÓN COMPLETA
# ==========================================================

def decode_and_validate_image(
    image_bytes: bytes,
) -> np.ndarray:

    # ------------------------------------------------------
    # 1. Tamaño
    # ------------------------------------------------------

    validate_image_size(
        image_bytes
    )


    # ------------------------------------------------------
    # 2. Intentar OpenCV
    #
    # JPG / PNG / WEBP normalmente entran aquí.
    # ------------------------------------------------------

    image = _decode_with_opencv(
        image_bytes
    )


    # ------------------------------------------------------
    # 3. Fallback Pillow
    # ------------------------------------------------------

    if image is None:

        image = _decode_with_pillow(
            image_bytes
        )


    # ------------------------------------------------------
    # 4. Ningún decoder pudo abrirlo
    # ------------------------------------------------------

    if image is None:

        raise InvalidUploadError(
            "El archivo recibido no es "
            "una imagen válida o utiliza "
            "un formato no compatible."
        )


    # ------------------------------------------------------
    # 5. Dimensiones
    # ------------------------------------------------------

    _validate_dimensions(
        image
    )


    return image