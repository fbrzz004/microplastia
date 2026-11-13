from datetime import datetime
from pathlib import Path
from typing import Sequence
from uuid import uuid4
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from app.core.config import settings
from app.models.result import ResultadoAnalisis
from app.models.sample import Muestra
from app.models.user import Usuario


BASE_DIR = Path(__file__).resolve().parent.parent.parent
REPORTS_SUBDIR = "reports"

TEXT = colors.HexColor("#203653")
MUTED = colors.HexColor("#8492A6")
BORDER = colors.HexColor("#DCE6F1")
SOFT_BLUE = colors.HexColor("#F4F8FF")


def _styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()

    return {
        "title": ParagraphStyle(
            "AdminReportTitle",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=22,
            leading=26,
            textColor=TEXT,
            alignment=0,
            spaceAfter=4,
        ),
        "subtitle": ParagraphStyle(
            "AdminReportSubtitle",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=10,
            leading=14,
            textColor=MUTED,
            spaceAfter=18,
        ),
        "section": ParagraphStyle(
            "AdminReportSection",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=13,
            leading=17,
            textColor=TEXT,
            spaceBefore=10,
            spaceAfter=8,
        ),
    }


def _footer(canvas, doc) -> None:
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MUTED)

    canvas.drawString(
        18 * mm,
        12 * mm,
        "MicroplastIA - Reporte administrativo",
    )

    canvas.drawRightString(
        A4[0] - 18 * mm,
        12 * mm,
        f"Página {doc.page}",
    )

    canvas.restoreState()


def _format_date(value: datetime | None) -> str:
    if value is None:
        return "Sin fecha"

    return value.strftime("%d/%m/%Y %H:%M")


def _table(
    rows: Sequence[Sequence[str]],
    header: Sequence[str] | None = None,
    widths: Sequence[float] | None = None,
) -> Table:

    data: list[list[str]] = []

    if header:
        data.append(list(header))

    data.extend(
        [list(row) for row in rows]
    )

    table = Table(
        data,
        colWidths=widths,
        hAlign="LEFT",
        repeatRows=1 if header else 0,
    )

    style = [
        ("FONTNAME", (0, 0), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("TEXTCOLOR", (0, 0), (-1, -1), TEXT),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LINEBELOW", (0, 0), (-1, -2), 0.35, BORDER),
    ]

    if header:
        style.extend([
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("BACKGROUND", (0, 0), (-1, 0), SOFT_BLUE),
        ])

    table.setStyle(
        TableStyle(style)
    )

    return table


def generate_admin_report(
    records: Sequence[
        tuple[
            ResultadoAnalisis,
            Muestra,
            Usuario,
        ]
    ],
    admin: Usuario,
    output_dir: Path | None = None,
) -> Path:
    """
    Genera un PDF administrativo con los análisis
    seleccionados desde el panel web.
    """

    directory = output_dir or (
        BASE_DIR
        / settings.static_dir
        / REPORTS_SUBDIR
    )

    directory.mkdir(
        parents=True,
        exist_ok=True,
    )

    timestamp = (
        datetime.now()
        .strftime("%Y%m%d_%H%M%S")
    )

    filename = (
        f"reporte_admin_"
        f"{admin.id_usuario}_"
        f"{timestamp}_"
        f"{uuid4().hex[:6]}.pdf"
    )

    path = directory / filename

    total_analisis = len(records)

    total_particulas = sum(
        resultado.total_particulas or 0
        for resultado, _, _ in records
    )

    confidencias = [
        resultado.confianza_promedio
        for resultado, _, _ in records
        if resultado.confianza_promedio
        is not None
    ]

    confianza_promedio = (
        sum(confidencias)
        / len(confidencias)
        if confidencias
        else 0.0
    )

    usuarios_unicos = len({
        usuario.id_usuario
        for _, _, usuario in records
    })

    fechas = [
        (
            resultado.fecha_creacion
            or muestra.fecha_registro
        )
        for resultado, muestra, _ in records
        if (
            resultado.fecha_creacion
            or muestra.fecha_registro
        ) is not None
    ]

    periodo = (
        f"{_format_date(min(fechas))} - "
        f"{_format_date(max(fechas))}"
        if fechas
        else "Sin fecha"
    )

    styles = _styles()

    story = [
        Paragraph(
            "MicroplastIA",
            styles["title"],
        ),
        Paragraph(
            "Reporte administrativo de análisis",
            styles["section"],
        ),
        Paragraph(
            "Administrador: "
            f"{escape(admin.nombre)} "
            f"({escape(admin.correo)})<br/>"
            f"Generado: "
            f"{_format_date(datetime.now())}",
            styles["subtitle"],
        ),
        Paragraph(
            "Resumen",
            styles["section"],
        ),
        _table(
            [
                [
                    "Análisis incluidos",
                    str(total_analisis),
                ],
                [
                    "Usuarios incluidos",
                    str(usuarios_unicos),
                ],
                [
                    "Partículas totales",
                    str(total_particulas),
                ],
                [
                    "Confianza promedio",
                    (
                        f"{confianza_promedio * 100:.1f}%"
                    ),
                ],
                [
                    "Periodo",
                    periodo,
                ],
            ],
            widths=[
                60 * mm,
                105 * mm,
            ],
        ),
        Spacer(
            1,
            7 * mm,
        ),
        Paragraph(
            "Detalle de análisis",
            styles["section"],
        ),
    ]

    rows: list[list[str]] = []

    for (
        resultado,
        muestra,
        usuario
    ) in records:

        codigo = (
            muestra.descripcion
            or f"MUESTRA-{muestra.id_muestra}"
        )

        nombre_usuario = usuario.nombre

        if usuario.apellido:
            nombre_usuario += (
                f" {usuario.apellido}"
            )

        fecha = (
            resultado.fecha_creacion
            or muestra.fecha_registro
        )

        modelo = "—"

        if resultado.modelo_nombre:
            modelo = resultado.modelo_nombre

            if resultado.modelo_version:
                modelo += (
                    f" v{resultado.modelo_version}"
                )

        rows.append([
            escape(str(codigo)),
            escape(nombre_usuario),
            _format_date(fecha),
            str(
                resultado.total_particulas
                or 0
            ),
            (
                f"{(
                    resultado.confianza_promedio
                    or 0
                ) * 100:.1f}%"
            ),
            escape(modelo),
        ])

    story.append(
        _table(
            rows,
            header=[
                "Muestra",
                "Usuario",
                "Fecha",
                "Partículas",
                "Confianza",
                "Modelo",
            ],
            widths=[
                31 * mm,
                35 * mm,
                32 * mm,
                21 * mm,
                22 * mm,
                30 * mm,
            ],
        )
    )

    document = SimpleDocTemplate(
        str(path),
        pagesize=A4,
        leftMargin=14 * mm,
        rightMargin=14 * mm,
        topMargin=16 * mm,
        bottomMargin=20 * mm,
        title=(
            "Reporte administrativo - "
            "MicroplastIA"
        ),
        author="MicroplastIA",
    )

    document.build(
        story,
        onFirstPage=_footer,
        onLaterPages=_footer,
    )

    return path
