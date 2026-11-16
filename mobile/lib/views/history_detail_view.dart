import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../models/analysis_result.dart';
import '../viewmodels/history_detail_viewmodel.dart';

class HistoryDetailView extends StatelessWidget {
  final int resultId;

  const HistoryDetailView({
    super.key,
    required this.resultId,
  });

  static const Color azul = Color(0xFF1976E9);
  static const Color texto = Color(0xFF203653);
  static const Color secundario = Color(0xFF8492A6);
  static const Color fondo = Color(0xFFF5F8FC);
  static const Color borde = Color(0xFFE3EAF2);
  static const Color verde = Color(0xFF08B981);
  static const Color naranja = Color(0xFFFFA000);
  static const Color morado = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryDetailViewModel()..cargar(resultId),
      child: _HistoryDetailContent(
        resultId: resultId,
      ),
    );
  }
}

class _HistoryDetailContent extends StatelessWidget {
  final int resultId;

  const _HistoryDetailContent({
    required this.resultId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryDetailViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: HistoryDetailView.texto,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text(
              'Detalle del análisis',
              style: TextStyle(
                color: HistoryDetailView.texto,
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
          ),
          body: _contenido(
            context,
            vm,
          ),
        );
      },
    );
  }

  Widget _contenido(
    BuildContext context,
    HistoryDetailViewModel vm,
  ) {
    if (vm.isLoading && vm.detalle == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: HistoryDetailView.azul,
        ),
      );
    }

    if (vm.errorMessage != null && vm.detalle == null) {
      return _Estado(
        icono: Icons.cloud_off_outlined,
        titulo: 'No se pudo cargar el análisis',
        mensaje: vm.errorMessage!,
        textoBoton: 'Reintentar',
        onPressed: () => vm.reintentar(resultId),
      );
    }

    final detalle = vm.detalle;

    if (detalle == null) {
      return const _Estado(
        icono: Icons.analytics_outlined,
        titulo: 'Análisis no disponible',
        mensaje: 'No encontramos información para esta muestra.',
      );
    }

    final filtradas = vm.deteccionesFiltradas;

    return RefreshIndicator(
      color: HistoryDetailView.azul,
      onRefresh: () => vm.reintentar(resultId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          28,
        ),
        children: [
          _encabezado(detalle),
          const SizedBox(height: 20),
          _ImagenAnalisisFiltrable(
            annotatedUrl: _resolverImagen(
              detalle.annotatedImageUrl,
            ),
            originalUrl: _resolverImagen(
              detalle.originalImageUrl,
            ),
            detections: filtradas,
            selectedClassId: vm.selectedClassId,
          ),
          const SizedBox(height: 18),
          _filtros(
            vm,
          ),
          if (!vm.canFilter) ...[
            const SizedBox(height: 10),
            const Text(
              'Los filtros visuales estarán disponibles '
              'en los análisis nuevos.',
              style: TextStyle(
                color: HistoryDetailView.secundario,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            'Resumen de resultados',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: HistoryDetailView.texto,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            vm.selectedClassId == null
                ? '${detalle.totalParticles} partículas detectadas'
                : '${filtradas.length} ${_nombreFiltro(vm.selectedClassId!)} detectadas',
            style: const TextStyle(
              fontSize: 14,
              color: HistoryDetailView.secundario,
            ),
          ),
          const SizedBox(height: 14),
          _tarjetaConfianza(detalle),
          const SizedBox(height: 18),
          _tarjetasCategorias(
            vm,
          ),
          const SizedBox(height: 22),
          _seccionTecnica(detalle),
          if (filtradas.isNotEmpty) ...[
            const SizedBox(height: 22),
            _listaDetecciones(
              filtradas,
            ),
          ],
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              'Aviso: ${vm.errorMessage}',
              style: const TextStyle(
                color: HistoryDetailView.naranja,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _encabezado(
    AnalysisDetail detalle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detalle.sampleId.isEmpty
              ? 'Muestra #${detalle.id}'
              : detalle.sampleId,
          style: const TextStyle(
            color: HistoryDetailView.texto,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: HistoryDetailView.secundario,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _formatearFecha(
                  detalle.createdAt,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: HistoryDetailView.secundario,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filtros(
    HistoryDetailViewModel vm,
  ) {
    final items = [
      const _Filtro(
        classId: null,
        nombre: 'Todos',
        color: HistoryDetailView.texto,
        icono: Icons.grid_view_rounded,
      ),
      const _Filtro(
        classId: 1,
        nombre: 'Fibras',
        color: HistoryDetailView.azul,
        icono: Icons.linear_scale_rounded,
      ),
      const _Filtro(
        classId: 2,
        nombre: 'Fragmentos',
        color: HistoryDetailView.verde,
        icono: Icons.grain_rounded,
      ),
      const _Filtro(
        classId: 3,
        nombre: 'Gránulos',
        color: HistoryDetailView.naranja,
        icono: Icons.circle_outlined,
      ),
      const _Filtro(
        classId: 0,
        nombre: 'Orgánica',
        color: HistoryDetailView.morado,
        icono: Icons.blur_on_rounded,
      ),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];

          final selected = vm.selectedClassId == item.classId;

          final cantidad = item.classId == null
              ? vm.detalle?.totalParticles ?? 0
              : vm.contarClase(
                  item.classId!,
                );

          final enabled =
              item.classId == null || (vm.canFilter && cantidad > 0);

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled
                ? () => vm.seleccionarClase(
                      item.classId,
                    )
                : null,
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 180,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? item.color.withValues(
                        alpha: 0.12,
                      )
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? item.color : HistoryDetailView.borde,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icono,
                    size: 17,
                    color: enabled ? item.color : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.nombre} $cantidad',
                    style: TextStyle(
                      color: enabled ? item.color : Colors.grey.shade400,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaConfianza(
    AnalysisDetail detalle,
  ) {
    final confianzaValida = detalle.confidence > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: HistoryDetailView.azul,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confianza promedio del modelo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HistoryDetailView.texto,
              ),
            ),
          ),
          Text(
            confianzaValida ? '${detalle.confidencePercent}%' : 'N/D',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: HistoryDetailView.azul,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetasCategorias(
    HistoryDetailViewModel vm,
  ) {
    final categorias = [
      _Categoria(
        classId: 1,
        nombre: 'Fibras',
        cantidad: vm.contarClase(1),
        color: HistoryDetailView.azul,
        icono: Icons.linear_scale_rounded,
      ),
      _Categoria(
        classId: 2,
        nombre: 'Fragmentos',
        cantidad: vm.contarClase(2),
        color: HistoryDetailView.verde,
        icono: Icons.grain_rounded,
      ),
      _Categoria(
        classId: 3,
        nombre: 'Gránulos',
        cantidad: vm.contarClase(3),
        color: HistoryDetailView.naranja,
        icono: Icons.circle_outlined,
      ),
      _Categoria(
        classId: 0,
        nombre: 'Partícula orgánica',
        cantidad: vm.contarClase(0),
        color: HistoryDetailView.morado,
        icono: Icons.blur_on_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final ancho = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categorias.map(
            (categoria) {
              final selected = vm.selectedClassId == categoria.classId;

              final enabled = vm.canFilter && categoria.cantidad > 0;

              return SizedBox(
                width: ancho,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                  onTap: enabled
                      ? () => vm.seleccionarClase(
                            categoria.classId,
                          )
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? categoria.color.withValues(
                              alpha: 0.07,
                            )
                          : Colors.white,
                      border: Border.all(
                        color: selected
                            ? categoria.color
                            : HistoryDetailView.borde,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 37,
                          height: 37,
                          decoration: BoxDecoration(
                            color: categoria.color.withValues(
                              alpha: enabled ? 0.10 : 0.04,
                            ),
                            borderRadius: BorderRadius.circular(
                              11,
                            ),
                          ),
                          child: Icon(
                            categoria.icono,
                            color: enabled
                                ? categoria.color
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${categoria.cantidad}',
                                style: TextStyle(
                                  color: enabled
                                      ? categoria.color
                                      : Colors.grey.shade400,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                categoria.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: HistoryDetailView.secundario,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }

  Widget _seccionTecnica(
    AnalysisDetail detalle,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: HistoryDetailView.borde,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del procesamiento',
            style: TextStyle(
              color: HistoryDetailView.texto,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _FilaDato(
            icono: Icons.timer_outlined,
            etiqueta: 'Tiempo de inferencia',
            valor: detalle.processingTimeMs > 0
                ? '${detalle.processingTimeMs.toStringAsFixed(1)} ms'
                : 'No disponible',
          ),
          const SizedBox(height: 13),
          _FilaDato(
            icono: Icons.category_outlined,
            etiqueta: 'Tipos registrados',
            valor: '${detalle.breakdown.length}',
          ),
        ],
      ),
    );
  }

  Widget _listaDetecciones(
    List<AnalysisDetection> detecciones,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detecciones individuales',
          style: TextStyle(
            color: HistoryDetailView.texto,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...detecciones.asMap().entries.map(
          (entry) {
            final indice = entry.key + 1;

            final deteccion = entry.value;

            final color = _colorClase(
              deteccion.classId,
            );

            return Container(
              margin: const EdgeInsets.only(
                bottom: 8,
              ),
              padding: const EdgeInsets.all(
                13,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: HistoryDetailView.borde,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Text(
                      '$indice',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Text(
                      _nombreClase(
                        deteccion.className,
                      ),
                      style: const TextStyle(
                        color: HistoryDetailView.texto,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${(deteccion.confidence * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  static Color _colorClase(
    int classId,
  ) {
    switch (classId) {
      case 0:
        return HistoryDetailView.morado;
      case 1:
        return HistoryDetailView.azul;
      case 2:
        return HistoryDetailView.verde;
      case 3:
        return HistoryDetailView.naranja;
      default:
        return HistoryDetailView.texto;
    }
  }

  static String _nombreFiltro(
    int classId,
  ) {
    switch (classId) {
      case 0:
        return 'partículas orgánicas';
      case 1:
        return 'fibras';
      case 2:
        return 'fragmentos';
      case 3:
        return 'gránulos';
      default:
        return 'partículas';
    }
  }

  static String _nombreClase(
    String nombre,
  ) {
    switch (nombre.toLowerCase().trim()) {
      case 'fiber':
      case 'fibra':
      case 'fibras':
        return 'Fibra';

      case 'fragment':
      case 'fragmento':
      case 'fragmentos':
        return 'Fragmento';

      case 'pellet':
      case 'pellets':
      case 'granulo':
      case 'gránulo':
      case 'granulos':
      case 'gránulos':
        return 'Gránulo';

      case 'dirt':
      case 'suciedad':
      case 'particula organica':
      case 'partícula orgánica':
        return 'Partícula orgánica';

      default:
        return nombre.isEmpty ? 'Partícula detectada' : nombre;
    }
  }

  static String _formatearFecha(
    DateTime? fecha,
  ) {
    if (fecha == null) {
      return 'Fecha no disponible';
    }

    final local = fecha.toLocal();

    final dia = local.day.toString().padLeft(2, '0');

    final mes = local.month.toString().padLeft(2, '0');

    final hora = local.hour.toString().padLeft(2, '0');

    final minuto = local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${local.year} · '
        '$hora:$minuto';
  }

  static String? _resolverImagen(
    String? url,
  ) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }

    final limpia = url.trim();

    if (limpia.startsWith(
          'https://',
        ) ||
        limpia.startsWith(
          'http://',
        )) {
      return limpia;
    }

    final base = AppConfig.apiBaseUrl.endsWith(
      '/',
    )
        ? AppConfig.apiBaseUrl.substring(
            0,
            AppConfig.apiBaseUrl.length - 1,
          )
        : AppConfig.apiBaseUrl;

    return '$base'
        '${limpia.startsWith('/') ? '' : '/'}'
        '$limpia';
  }
}

class _ImagenAnalisisFiltrable extends StatefulWidget {
  final String? annotatedUrl;
  final String? originalUrl;

  final List<AnalysisDetection> detections;

  final int? selectedClassId;

  const _ImagenAnalisisFiltrable({
    required this.annotatedUrl,
    required this.originalUrl,
    required this.detections,
    required this.selectedClassId,
  });

  @override
  State<_ImagenAnalisisFiltrable> createState() =>
      _ImagenAnalisisFiltrableState();
}

class _ImagenAnalisisFiltrableState extends State<_ImagenAnalisisFiltrable> {
  ImageStream? _imageStream;
  ImageStreamListener? _listener;

  double? _imageWidth;
  double? _imageHeight;

  @override
  void didUpdateWidget(
    covariant _ImagenAnalisisFiltrable oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.originalUrl != widget.originalUrl) {
      _cargarDimensiones();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _cargarDimensiones();
  }

  void _cargarDimensiones() {
    final url = widget.originalUrl;

    if (url == null || url.isEmpty) {
      return;
    }

    _listener != null
        ? _imageStream?.removeListener(
            _listener!,
          )
        : null;

    final provider = NetworkImage(url);

    final stream = provider.resolve(
      createLocalImageConfiguration(
        context,
      ),
    );

    final listener = ImageStreamListener(
      (
        ImageInfo info,
        bool synchronousCall,
      ) {
        if (!mounted) {
          return;
        }

        setState(() {
          _imageWidth = info.image.width.toDouble();

          _imageHeight = info.image.height.toDouble();
        });
      },
    );

    _imageStream = stream;
    _listener = listener;

    stream.addListener(
      listener,
    );
  }

  @override
  void dispose() {
    if (_listener != null) {
      _imageStream?.removeListener(
        _listener!,
      );
    }

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final filtered = widget.selectedClassId != null;

    final url = filtered ? widget.originalUrl : widget.annotatedUrl;

    return Container(
      height: 260,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: HistoryDetailView.borde,
        ),
      ),
      child: url == null
          ? const _SinImagen()
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (
                    context,
                    child,
                    progress,
                  ) {
                    if (progress == null) {
                      return child;
                    }

                    return const Center(
                      child: CircularProgressIndicator(
                        color: HistoryDetailView.azul,
                      ),
                    );
                  },
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const _SinImagen();
                  },
                ),
                if (filtered && _imageWidth != null && _imageHeight != null)
                  CustomPaint(
                    painter: _DetectionPainter(
                      detections: widget.detections,
                      imageWidth: _imageWidth!,
                      imageHeight: _imageHeight!,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<AnalysisDetection> detections;

  final double imageWidth;
  final double imageHeight;

  const _DetectionPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (imageWidth <= 0 || imageHeight <= 0) {
      return;
    }

    final scale = math.min(
      size.width / imageWidth,
      size.height / imageHeight,
    );

    final displayedWidth = imageWidth * scale;

    final displayedHeight = imageHeight * scale;

    final offsetX = (size.width - displayedWidth) / 2;

    final offsetY = (size.height - displayedHeight) / 2;

    for (final detection in detections) {
      if (detection.box.length != 4) {
        continue;
      }

      final x1 = offsetX + detection.box[0] * scale;

      final y1 = offsetY + detection.box[1] * scale;

      final x2 = offsetX + detection.box[2] * scale;

      final y2 = offsetY + detection.box[3] * scale;

      final color = _colorForClass(
        detection.classId,
      );

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRect(
        Rect.fromLTRB(
          x1,
          y1,
          x2,
          y2,
        ),
        paint,
      );
    }
  }

  Color _colorForClass(
    int classId,
  ) {
    switch (classId) {
      case 0:
        return HistoryDetailView.morado;

      case 1:
        return HistoryDetailView.azul;

      case 2:
        return HistoryDetailView.verde;

      case 3:
        return HistoryDetailView.naranja;

      default:
        return Colors.white;
    }
  }

  @override
  bool shouldRepaint(
    covariant _DetectionPainter oldDelegate,
  ) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight;
  }
}

class _SinImagen extends StatelessWidget {
  const _SinImagen();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 43,
              color: HistoryDetailView.secundario,
            ),
            SizedBox(height: 10),
            Text(
              'Imagen del análisis no disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HistoryDetailView.secundario,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _FilaDato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: 19,
          color: HistoryDetailView.secundario,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            etiqueta,
            style: const TextStyle(
              color: HistoryDetailView.secundario,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: HistoryDetailView.texto,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _Estado extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoBoton;
  final VoidCallback? onPressed;

  const _Estado({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoBoton,
    this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 54,
              color: HistoryDetailView.secundario,
            ),
            const SizedBox(height: 15),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HistoryDetailView.texto,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HistoryDetailView.secundario,
                fontSize: 13,
              ),
            ),
            if (textoBoton != null && onPressed != null) ...[
              const SizedBox(
                height: 18,
              ),
              ElevatedButton(
                onPressed: onPressed,
                child: Text(textoBoton!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Categoria {
  final int classId;
  final String nombre;
  final int cantidad;
  final Color color;
  final IconData icono;

  const _Categoria({
    required this.classId,
    required this.nombre,
    required this.cantidad,
    required this.color,
    required this.icono,
  });
}

class _Filtro {
  final int? classId;
  final String nombre;
  final Color color;
  final IconData icono;

  const _Filtro({
    required this.classId,
    required this.nombre,
    required this.color,
    required this.icono,
  });
}
