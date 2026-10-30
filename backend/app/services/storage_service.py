import uuid
from pathlib import Path

import cv2
import numpy as np

from app.core.config import settings


class StorageError(RuntimeError):
    """Error al almacenar una imagen."""

    pass


class StorageService:
    """
    Servicio encargado de almacenar las imágenes del análisis.

    Soporta dos modos:

    - local:
        Guarda las imágenes dentro de backend/static/.

    - supabase:
        Guarda las imágenes dentro de Supabase Storage.

    El resto de la aplicación no necesita saber qué sistema
    de almacenamiento se está utilizando.
    """

    def __init__(self):
        backend_dir = (
            Path(__file__)
            .resolve()
            .parent
            .parent
            .parent
        )

        # ==================================================
        # STORAGE LOCAL
        # ==================================================

        self.static_root = (
            backend_dir
            / settings.static_dir
        )

        self.originals_dir = (
            self.static_root
            / "uploads"
        )

        self.detections_dir = (
            self.static_root
            / "detections"
        )

        self.originals_dir.mkdir(
            parents=True,
            exist_ok=True,
        )

        self.detections_dir.mkdir(
            parents=True,
            exist_ok=True,
        )

        # ==================================================
        # SUPABASE
        # ==================================================

        self.supabase = None

        if (
            settings.storage_backend
            .strip()
            .lower()
            == "supabase"
        ):
            self._initialize_supabase()

    # ======================================================
    # SUPABASE
    # ======================================================

    def _initialize_supabase(
        self,
    ) -> None:
        """
        Inicializa el cliente de Supabase solamente cuando
        STORAGE_BACKEND=supabase.
        """

        if not settings.supabase_url:
            raise StorageError(
                "SUPABASE_URL no está configurado."
            )

        if not settings.supabase_secret_key:
            raise StorageError(
                "SUPABASE_SECRET_KEY no está configurado."
            )

        if not settings.supabase_storage_bucket:
            raise StorageError(
                "SUPABASE_STORAGE_BUCKET no está configurado."
            )

        try:
            from supabase import (
                Client,
                create_client,
            )

            self.supabase: Client = (
                create_client(
                    settings.supabase_url
                    .strip()
                    .rstrip("/"),
                    settings.supabase_secret_key
                    .strip(),
                )
            )

        except Exception as exc:
            raise StorageError(
                "No se pudo inicializar "
                "el cliente de Supabase."
            ) from exc

    # ======================================================
    # ARCHIVOS
    # ======================================================

    def _generate_filename(
        self,
        prefix: str,
    ) -> str:
        """
        Genera un nombre único para cada imagen.
        """

        random_id = uuid.uuid4().hex

        return (
            f"{prefix}_{random_id}.jpg"
        )

    def _encode_jpeg(
        self,
        image: np.ndarray,
    ) -> bytes:
        """
        Convierte la imagen OpenCV a JPEG antes de guardarla.

        Esto permite que una imagen original PNG, WEBP,
        HEIC, etc. sea normalizada a JPEG antes de
        enviarla al almacenamiento.
        """

        quality = int(
            settings.storage_jpeg_quality
        )

        success, encoded = cv2.imencode(
            ".jpg",
            image,
            [
                cv2.IMWRITE_JPEG_QUALITY,
                quality,
            ],
        )

        if not success:
            raise StorageError(
                "No se pudo convertir la imagen a JPEG."
            )

        return encoded.tobytes()

    # ======================================================
    # STORAGE LOCAL
    # ======================================================

    def _local_public_url(
        self,
        relative_path: str,
    ) -> str:
        """
        Construye la URL pública para imágenes almacenadas
        localmente.
        """

        relative_path = (
            relative_path
            .replace("\\", "/")
            .lstrip("/")
        )

        base_url = (
            settings.public_base_url
            .strip()
            .rstrip("/")
            if settings.public_base_url
            else ""
        )

        path = (
            f"/static/{relative_path}"
        )

        if base_url:
            return (
                f"{base_url}{path}"
            )

        return path

    def _save_local(
        self,
        image: np.ndarray,
        folder: str,
        prefix: str,
    ) -> str:
        """
        Guarda una imagen dentro del filesystem local.
        """

        filename = (
            self._generate_filename(
                prefix
            )
        )

        if folder == "uploads":
            destination = (
                self.originals_dir
                / filename
            )

        elif folder == "detections":
            destination = (
                self.detections_dir
                / filename
            )

        else:
            raise StorageError(
                "Carpeta de almacenamiento "
                "local no válida."
            )

        success = cv2.imwrite(
            str(destination),
            image,
        )

        if not success:
            raise StorageError(
                "No se pudo almacenar "
                "la imagen localmente."
            )

        return (
            self._local_public_url(
                f"{folder}/{filename}"
            )
        )

    # ======================================================
    # SUPABASE STORAGE
    # ======================================================

    def _save_supabase(
        self,
        image: np.ndarray,
        folder: str,
        prefix: str,
    ) -> str:
        """
        Guarda la imagen en Supabase Storage.

        La imagen se transforma primero a JPEG.
        """

        if self.supabase is None:
            raise StorageError(
                "Supabase Storage "
                "no está inicializado."
            )

        filename = (
            self._generate_filename(
                prefix
            )
        )

        object_path = (
            f"{folder}/{filename}"
        )

        jpeg_bytes = (
            self._encode_jpeg(
                image
            )
        )

        bucket = (
            settings
            .supabase_storage_bucket
            .strip()
        )

        try:
            # IMPORTANTE:
            #
            # storage3 espera bytes o una ruta de archivo.
            # No debemos pasar BytesIO aquí.
            #
            self.supabase.storage.from_(
                bucket
            ).upload(
                path=object_path,
                file=jpeg_bytes,
                file_options={
                    "cache-control": "3600",
                    "content-type": "image/jpeg",
                    "upsert": "false",
                },
            )

        except Exception as exc:
            raise StorageError(
                "No se pudo subir la imagen "
                "a Supabase Storage."
            ) from exc

        # ==================================================
        # URL PÚBLICA
        # ==================================================

        try:
            public_url = (
                self.supabase
                .storage
                .from_(bucket)
                .get_public_url(
                    object_path
                )
            )

            if isinstance(
                public_url,
                str,
            ):
                return public_url

            # Algunas versiones del SDK pueden devolver
            # estructuras diferentes.
            if isinstance(
                public_url,
                dict,
            ):
                possible_url = (
                    public_url.get(
                        "publicUrl"
                    )
                    or public_url.get(
                        "publicURL"
                    )
                    or public_url.get(
                        "public_url"
                    )
                )

                if possible_url:
                    return str(
                        possible_url
                    )

        except Exception:
            pass

        # ==================================================
        # FALLBACK URL
        # ==================================================

        base_url = (
            settings.supabase_url
            .strip()
            .rstrip("/")
        )

        return (
            f"{base_url}"
            f"/storage/v1/object/public/"
            f"{bucket}/"
            f"{object_path}"
        )

    # ======================================================
    # SELECTOR DE STORAGE
    # ======================================================

    def _save(
        self,
        image: np.ndarray,
        folder: str,
        prefix: str,
    ) -> str:
        """
        Decide automáticamente dónde almacenar la imagen.
        """

        backend = (
            settings.storage_backend
            .strip()
            .lower()
        )

        if backend == "supabase":
            return (
                self._save_supabase(
                    image=image,
                    folder=folder,
                    prefix=prefix,
                )
            )

        if backend == "local":
            return (
                self._save_local(
                    image=image,
                    folder=folder,
                    prefix=prefix,
                )
            )

        raise StorageError(
            "STORAGE_BACKEND debe ser "
            "'local' o 'supabase'."
        )

    # ======================================================
    # API PÚBLICA DEL SERVICIO
    # ======================================================

    def save_original_image(
        self,
        image: np.ndarray,
    ) -> str:
        """
        Guarda la imagen original normalizada.
        """

        return (
            self._save(
                image=image,
                folder="uploads",
                prefix="original",
            )
        )

    def save_annotated_image(
        self,
        image: np.ndarray,
    ) -> str:
        """
        Guarda la imagen procesada con las detecciones.
        """

        return (
            self._save(
                image=image,
                folder="detections",
                prefix="annotated",
            )
        )


storage_service = StorageService()