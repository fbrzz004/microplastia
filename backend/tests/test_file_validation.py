from io import BytesIO

from PIL import Image

from app.core.file_validation import (
    decode_and_validate_image,
    validate_content_type,
)


# ==========================================================
# CREAR IMAGEN
# ==========================================================

def crear_imagen(
    formato: str,
) -> bytes:

    image = Image.new(
        "RGB",
        (200, 150),
        color=(120, 160, 200),
    )

    buffer = BytesIO()

    image.save(
        buffer,
        format=formato,
    )

    return buffer.getvalue()


# ==========================================================
# JPEG
# ==========================================================

def test_jpeg_is_valid():

    image = decode_and_validate_image(
        crear_imagen(
            "JPEG"
        )
    )

    assert image is not None

    assert image.shape[
        0
    ] == 150

    assert image.shape[
        1
    ] == 200


# ==========================================================
# PNG
# ==========================================================

def test_png_is_valid():

    image = decode_and_validate_image(
        crear_imagen(
            "PNG"
        )
    )

    assert image is not None


# ==========================================================
# WEBP
# ==========================================================

def test_webp_is_valid():

    image = decode_and_validate_image(
        crear_imagen(
            "WEBP"
        )
    )

    assert image is not None


# ==========================================================
# MIME WEBP
# ==========================================================

def test_webp_content_type():

    validate_content_type(
        "image/webp"
    )


# ==========================================================
# MIME HEIC
# ==========================================================

def test_heic_content_type():

    validate_content_type(
        "image/heic"
    )


# ==========================================================
# MIME HEIF
# ==========================================================

def test_heif_content_type():

    validate_content_type(
        "image/heif"
    )


# ==========================================================
# MIME INVÁLIDO
# ==========================================================

def test_invalid_content_type():

    try:

        validate_content_type(
            "text/plain"
        )

        assert False, (
            "Debió rechazar text/plain"
        )

    except ValueError:

        assert True