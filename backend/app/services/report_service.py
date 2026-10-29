from datetime import datetime
from pathlib import Path
from typing import Dict, Sequence
from uuid import uuid4
from xml.sax.saxutils import escape

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from app.core.config import settings
from app.models.result import ResultadoAnalisis
from app.models.user import Usuario

BASE_DIR = Path(__file__).resolve().parent.parent.parent
REPORTS_SUBDIR = "reports"

BLUE = colors.HexColor("#1976E9")
TEXT = colors.HexColor("#203653")
MUTED = colors.HexColor("#8492A6")
BORDER = colors.HexColor("#DCE6F1")
SOFT_BLUE = colors.HexColor("#F4F8FF")

MAX_IMAGE_WIDTH = 155 * mm
MAX_IMAGE_HEIGHT = 95 * mm


def _styles() -> Dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()

    return {
        "title": ParagraphStyle(
            "ReportTitle",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=22,
            leading=26,
            textColor=TEXT,
            alignment=0,
            spaceAfter=4,
        ),
        "subtitle": ParagraphStyle(
            "ReportSubtitle",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=10,
            leading=14,
            textColor=MUTED,
            spaceAfter=18,
        ),
        "section": ParagraphStyle(
            "ReportSection",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=13,
            leading=17,
            textColor=TEXT,
            spaceBefore=10,
            spaceAfter=8,
        ),
        "body": ParagraphStyle(
            "ReportBody",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=10,
            leading=14,
            textColor=TEXT,
        ),
        "meta": ParagraphStyle(
            "ReportMeta",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9,
            leading=13,
            textColor=MUTED,
            spaceAfter=8,
        ),
        "sample": ParagraphStyle(
            "ReportSample",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=15,
            leading=19,
            textColor=TEXT,
            spaceAfter=2,
        ),
    }


def _footer(canvas, doc) -> None:
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(18 * mm, 12 * mm, "MicroplastIA - Reporte de análisis")
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


def _sample_id(result: ResultadoAnalisis) -> str:
    sample = result.muestra

    return sample.descripcion or f"MUESTRA-{sample.id_muestra:04d}"


def _created_at(result: ResultadoAnalisis) -> datetime | None:
    return (
        result.fecha_creacion
        or result.muestra.fecha_registro
    )


def _annotated_image(url: str | None) -> Image | None:
    if not url:
        return None

    relative = url.split("/static/", 1)[-1].lstrip("/")
    path = BASE_DIR / settings.static_dir / relative

    if not path.is_file():
        return None

    with PILImage.open(path) as image:
        width, height = image.size

    if width <= 0 or height <= 0:
        return None

    ratio = min(
        MAX_IMAGE_WIDTH / width,
        MAX_IMAGE_HEIGHT / height,
        1.0,
    )

    return Image(
        str(path),
        width=width * ratio,
        height=height * ratio,
    )


def _summary_stats(
    results: Sequence[ResultadoAnalisis],
) -> list[list[str]]:
    total_particles = sum(result.total_particulas for result in results)
    confidences = [
        result.confianza_promedio
        for result in results
        if result.confianza_promedio is not None
    ]
    average_confidence = (
        sum(confidences) / len(confidences)
        if confidences
        else 0.0
    )
    dates = [
        _created_at(result)
        for result in results
        if _created_at(result) is not None
    ]

    period = (
        f"{_format_date(min(dates))} - {_format_date(max(dates))}"
        if dates
        else "Sin fecha"
    )

    return [
        ["Análisis incluidos", str(len(results))],
        ["Partículas totales", str(total_particles)],
        ["Confianza promedio", f"{average_confidence * 100:.1f}%"],
        ["Periodo", period],
    ]


def _breakdown_totals(
    results: Sequence[ResultadoAnalisis],
) -> list[list[str]]:
    totals: Dict[str, int] = {}

    for result in results:
        for name, count in (result.desglose or {}).items():
            totals[name] = totals.get(name, 0) + int(count)

    return [
        [name, str(count)]
        for name, count in sorted(
            totals.items(),
            key=lambda item: item[1],
            reverse=True,
        )
    ]


def _table(
    rows: Sequence[Sequence[str]],
    header: Sequence[str] | None = None,
    widths: Sequence[float] | None = None,
) -> Table:
    data = []

    if header:
        data.append(list(header))

    data.extend([list(row) for row in rows])

    table = Table(data, colWidths=widths, hAlign="LEFT")

    style = [
        ("FONTNAME", (0, 0), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("TEXTCOLOR", (0, 0), (-1, -1), TEXT),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("LINEBELOW", (0, 0), (-1, -2), 0.4, BORDER),
    ]

    if header:
        style.extend([
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("BACKGROUND", (0, 0), (-1, 0), SOFT_BLUE),
        ])

    table.setStyle(TableStyle(style))

    return table


def generate_report(
    results: Sequence[ResultadoAnalisis],
    user: Usuario,
    output_dir: Path | None = None,
) -> Path:
    """Build a PDF report for the given analyses and return its path."""

    directory = output_dir or (
        BASE_DIR / settings.static_dir / REPORTS_SUBDIR
    )
    directory.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = (
        f"reporte_{user.id_usuario}_{timestamp}_"
        f"{uuid4().hex[:6]}.pdf"
    )
    path = directory / filename

    styles = _styles()
    story = [
        Paragraph("MicroplastIA", styles["title"]),
        Paragraph("Reporte de análisis de microplásticos", styles["section"]),
        Paragraph(
            "Usuario: "
            f"{escape(user.nombre)} "
            f"({escape(user.correo)})<br/>"
            f"Generado: {_format_date(datetime.now())}",
            styles["subtitle"],
        ),
        Paragraph("Resumen", styles["section"]),
        _table(
            _summary_stats(results),
            widths=[60 * mm, 100 * mm],
        ),
    ]

    breakdown = _breakdown_totals(results)

    if breakdown:
        story.extend([
            Spacer(1, 6 * mm),
            Paragraph("Desglose por morfología", styles["section"]),
            _table(
                breakdown,
                header=["Morfología", "Cantidad"],
                widths=[60 * mm, 40 * mm],
            ),
        ])

    story.extend([
        Spacer(1, 6 * mm),
        Paragraph("Análisis incluidos", styles["section"]),
        _table(
            [
                [
                    _sample_id(result),
                    _format_date(_created_at(result)),
                    str(result.total_particulas),
                    f"{result.confianza_promedio * 100:.1f}%",
                ]
                for result in results
            ],
            header=["Muestra", "Fecha", "Partículas", "Confianza"],
            widths=[45 * mm, 45 * mm, 30 * mm, 30 * mm],
        ),
        PageBreak(),
    ])

    for index, result in enumerate(results):
        story.extend([
            Paragraph(
                escape(_sample_id(result)),
                styles["sample"],
            ),
            Paragraph(
                f"{_format_date(_created_at(result))} · "
                f"{result.total_particulas} partículas · "
                f"confianza {result.confianza_promedio * 100:.1f}% · "
                f"{result.tiempo_procesamiento_ms:.0f} ms",
                styles["meta"],
            ),
        ])

        image = _annotated_image(result.imagen_anotada_url)

        if image is not None:
            story.extend([image, Spacer(1, 5 * mm)])

        result_breakdown = [
            [name, str(count)]
            for name, count in (result.desglose or {}).items()
        ]

        if result_breakdown:
            story.extend([
                Paragraph("Morfologías detectadas", styles["section"]),
                _table(
                    result_breakdown,
                    header=["Morfología", "Cantidad"],
                    widths=[60 * mm, 40 * mm],
                ),
            ])

        if index < len(results) - 1:
            story.append(PageBreak())

    document = SimpleDocTemplate(
        str(path),
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=18 * mm,
        bottomMargin=20 * mm,
        title="Reporte de análisis - MicroplastIA",
        author="MicroplastIA",
    )

    document.build(
        story,
        onFirstPage=_footer,
        onLaterPages=_footer,
    )

    return path
