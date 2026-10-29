import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/analysis_result.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel;

  static const Color azul = Color(0xFF1976E9);
  static const Color oscuro = Color(0xFF203653);
  static const Color gris = Color(0xFF8290A5);

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.cargarDatos();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _recargar() => _viewModel.cargarDatos();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final ultimo = _viewModel.ultimoAnalisis;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _recargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(17, 20, 17, 30),
                children: [
                  const Text(
                    'Hola, investigador',
                    style: TextStyle(
                      color: oscuro,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Resumen de tus análisis recientes',
                    style: TextStyle(color: gris, fontSize: 12),
                  ),
                  const SizedBox(height: 27),

                  // Resumen con estadísticas reales
                  Container(
                    padding: const EdgeInsets.fromLTRB(17, 15, 17, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102B4D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Análisis realizados',
                          style: TextStyle(
                            color: Color(0xFFD3DFEF),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_viewModel.isLoading)
                          const SizedBox(
                            height: 36,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          Text(
                            _viewModel.errorMessage == null
                                ? '${_viewModel.totalAnalisis}'
                                : '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        const SizedBox(height: 5),
                        Text(
                          _viewModel.isLoading
                              ? 'Cargando estadísticas...'
                              : _viewModel.errorMessage != null
                                  ? 'No se pudieron cargar los datos'
                                  : 'Esta semana: ${_viewModel.analisisEstaSemana}',
                          style: const TextStyle(
                            color: Color(0xFFB8C8DC),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  const Text(
                    'Acciones rápidas',
                    style: TextStyle(
                      color: Color(0xFF202938),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _AccionRapida(
                          icono: Icons.biotech_rounded,
                          titulo: 'Nueva\nmuestra',
                          colorFondo: const Color(0xFFE0F5FF),
                          colorIcono: azul,
                          onTap: () => context.go('/analysis'),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _AccionRapida(
                          icono: Icons.history_rounded,
                          titulo: 'Historial',
                          colorFondo: const Color(0xFFE2F8EF),
                          colorIcono: const Color(0xFF28B77A),
                          onTap: () => context.go('/history'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 45),

                  const Text(
                    'Último análisis',
                    style: TextStyle(
                      color: Color(0xFF202938),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_viewModel.isLoading && ultimo == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: azul),
                      ),
                    )
                  else if (_viewModel.errorMessage != null)
                    _EstadoVacio(
                      mensaje: _viewModel.errorMessage!,
                      boton: 'Reintentar',
                      onTap: _recargar,
                    )
                  else if (ultimo == null)
                    _EstadoVacio(
                      mensaje: 'Aún no tienes análisis registrados.',
                      boton: 'Analizar una muestra',
                      onTap: () => context.go('/analysis'),
                    )
                  else
                    _TarjetaUltimoAnalisis(
                      analisis: ultimo,
                      onTap: () => context.go('/history/${ultimo.id}'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccionRapida extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color colorFondo;
  final Color colorIcono;
  final VoidCallback onTap;

  const _AccionRapida({
    required this.icono,
    required this.titulo,
    required this.colorFondo,
    required this.colorIcono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E8F3)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: colorFondo,
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, size: 16, color: colorIcono),
              ),
              const SizedBox(height: 7),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF202938),
                  fontSize: 10,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaUltimoAnalisis extends StatelessWidget {
  final AnalysisSummary analisis;
  final VoidCallback onTap;

  const _TarjetaUltimoAnalisis({
    required this.analisis,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = analisis.createdAt?.toLocal();
    final fechaTexto = fecha == null
        ? ''
        : '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E8F3)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 75,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.biotech_outlined,
                color: Color(0xFF8290A5),
                size: 34,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analisis.sampleId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF202938),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${analisis.totalParticles} partículas detectadas',
                    style: const TextStyle(
                      color: Color(0xFF8290A5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Confianza promedio ${analisis.confidencePercent}%',
                    style: const TextStyle(
                      color: Color(0xFF16B978),
                      fontSize: 10,
                    ),
                  ),
                  if (fechaTexto.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      fechaTexto,
                      style: const TextStyle(
                        color: Color(0xFF8290A5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final String mensaje;
  final String boton;
  final VoidCallback onTap;

  const _EstadoVacio({
    required this.mensaje,
    required this.boton,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E8F3)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF687B98),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onTap,
            child: Text(boton),
          ),
        ],
      ),
    );
  }
}
