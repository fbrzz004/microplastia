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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryDetailViewModel()..cargar(resultId),
      child: _HistoryDetailContent(resultId: resultId),
    );
  }
}

class _HistoryDetailContent extends StatelessWidget {
  final int resultId;

  const _HistoryDetailContent({required this.resultId});

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
            centerTitle: false,
          ),
          body: _contenido(context, vm),
        );
      },
    );
  }

  Widget _contenido(BuildContext context, HistoryDetailViewModel vm) {
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

    return RefreshIndicator(
      color: HistoryDetailView.azul,
      onRefresh: () => vm.reintentar(resultId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _encabezado(detalle),
          const SizedBox(height: 20),
          _ImagenAnalisis(url: _resolverImagen(detalle.annotatedImageUrl)),
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
            '${detalle.totalParticles} partículas detectadas',
            style: const TextStyle(
              fontSize: 14,
              color: HistoryDetailView.secundario,
            ),
          ),
          const SizedBox(height: 14),
          _tarjetaConfianza(detalle),
          const SizedBox(height: 18),
          _tarjetasCategorias(detalle),
          const SizedBox(height: 22),
          _seccionTecnica(detalle),
          if (detalle.detections.isNotEmpty) ...[
            const SizedBox(height: 22),
            _listaDetecciones(detalle),
          ],
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              'Aviso: ${vm.errorMessage}',
              style: const TextStyle(color: HistoryDetailView.naranja),
            ),
          ],
        ],
      ),
    );
  }

  Widget _encabezado(AnalysisDetail detalle) {
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
                _formatearFecha(detalle.createdAt),
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

  Widget _tarjetaConfianza(AnalysisDetail detalle) {
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
            confianzaValida
                ? '${detalle.confidencePercent}%'
                : 'N/D',
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

  Widget _tarjetasCategorias(AnalysisDetail detalle) {
    final categorias = <_Categoria>[
      _Categoria(
        'Fibras',
        _contar(detalle.breakdown, ['fiber', 'fibra', 'fibras']),
        const Color(0xFF1976E9),
        Icons.linear_scale_rounded,
      ),
      _Categoria(
        'Fragmentos',
        _contar(detalle.breakdown, ['fragment', 'fragmento', 'fragmentos']),
        const Color(0xFF08B981),
        Icons.grain_rounded,
      ),
      _Categoria(
        'Pellets',
        _contar(detalle.breakdown, ['pellet', 'pellets']),
        const Color(0xFFFFA000),
        Icons.circle_outlined,
      ),
      _Categoria(
        'Suciedad',
        _contar(detalle.breakdown, ['dirt', 'suciedad']),
        const Color(0xFF8B5CF6),
        Icons.blur_on_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categorias.map((categoria) {
            return SizedBox(
              width: ancho,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: HistoryDetailView.borde,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 37,
                      height: 37,
                      decoration: BoxDecoration(
                        color: categoria.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        categoria.icono,
                        color: categoria.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${categoria.cantidad}',
                            style: TextStyle(
                              color: categoria.color,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            categoria.nombre,
                            maxLines: 1,
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
            );
          }).toList(),
        );
      },
    );
  }

  Widget _seccionTecnica(AnalysisDetail detalle) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: HistoryDetailView.borde),
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

  Widget _listaDetecciones(AnalysisDetail detalle) {
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
        ...detalle.detections.asMap().entries.map((entry) {
          final indice = entry.key + 1;
          final deteccion = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: HistoryDetailView.borde),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$indice',
                    style: const TextStyle(
                      color: HistoryDetailView.azul,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _nombreClase(deteccion.className),
                    style: const TextStyle(
                      color: HistoryDetailView.texto,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${(deteccion.confidence * 100).round()}%',
                  style: const TextStyle(
                    color: HistoryDetailView.verde,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static int _contar(
    Map<String, int> breakdown,
    List<String> posiblesNombres,
  ) {
    var total = 0;

    for (final entry in breakdown.entries) {
      final clave = entry.key.toLowerCase().trim();
      if (posiblesNombres.contains(clave)) {
        total += entry.value;
      }
    }

    return total;
  }

  static String _nombreClase(String nombre) {
    switch (nombre.toLowerCase().trim()) {
      case 'fiber':
        return 'Fibra';
      case 'fragment':
        return 'Fragmento';
      case 'pellet':
        return 'Pellet';
      case 'dirt':
        return 'Suciedad';
      default:
        return nombre.isEmpty ? 'Partícula detectada' : nombre;
    }
  }

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha no disponible';

    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${local.year} · $hora:$minuto';
  }

  static String? _resolverImagen(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final limpia = url.trim();

    if (limpia.startsWith('https://') ||
        limpia.startsWith('http://')) {
      return limpia;
    }

    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(
            0,
            AppConfig.apiBaseUrl.length - 1,
          )
        : AppConfig.apiBaseUrl;

    return '$base${limpia.startsWith('/') ? '' : '/'}$limpia';
  }
}

class _ImagenAnalisis extends StatelessWidget {
  final String? url;

  const _ImagenAnalisis({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: HistoryDetailView.borde),
      ),
      child: url == null
          ? const _SinImagen()
          : Image.network(
              url!,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return const Center(
                  child: CircularProgressIndicator(
                    color: HistoryDetailView.azul,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const _SinImagen();
              },
            ),
    );
  }
}

class _SinImagen extends StatelessWidget {
  const _SinImagen();

  @override
  Widget build(BuildContext context) {
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
  Widget build(BuildContext context) {
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
  Widget build(BuildContext context) {
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
              const SizedBox(height: 18),
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
  final String nombre;
  final int cantidad;
  final Color color;
  final IconData icono;

  const _Categoria(
    this.nombre,
    this.cantidad,
    this.color,
    this.icono,
  );
}
