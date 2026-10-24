import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../viewmodels/analysis_viewmodel.dart';
import '../viewmodels/history_viewmodel.dart';

class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  final ImagePicker _picker = ImagePicker();

  XFile? _imagenSeleccionada;
  Uint8List? _imagenBytes;
  String? _mensaje;
  bool _error = false;

  static const Color azul = Color(0xFF1976E9);
  static const Color texto = Color(0xFF203653);
  static const Color secundario = Color(0xFF8492A6);
  static const Color fondoImagen = Color(0xFFF0F5F8);
  static const Color celeste = Color(0xFFE0F5FC);

  Future<void> _cargarImagen(ImageSource source) async {
    try {
      final archivo = await _picker.pickImage(source: source);

      if (archivo == null) return;

      final bytes = await archivo.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imagenSeleccionada = archivo;
        _imagenBytes = bytes;
        _mensaje = null;
        _error = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensaje = source == ImageSource.camera
            ? 'No se pudo tomar la fotografía: $e'
            : 'No se pudo seleccionar la imagen: $e';
        _error = true;
      });
    }
  }

  Future<void> _seleccionarImagen() =>
      _cargarImagen(ImageSource.gallery);

  Future<void> _tomarFotografia() =>
      _cargarImagen(ImageSource.camera);

  
  Future<void> _subirImagen() async {
    if (_imagenSeleccionada == null || _imagenBytes == null) {
      setState(() {
        _mensaje = 'Primero selecciona una imagen.';
        _error = true;
      });
      return;
    }

    final viewModel = context.read<AnalysisViewModel>();

    final correcto = await viewModel.analizarImagen(
      bytes: _imagenBytes!,
      filename: _imagenSeleccionada!.name,
    );

    if (!mounted) return;

    if (correcto) {
      unawaited(context.read<HistoryViewModel>().refrescar());
      context.go('/result');
    } else {
      setState(() {
        _mensaje = viewModel.errorMessage;
        _error = true;
      });
    }
  }

  void _quitarImagen() {
  if (context.read<AnalysisViewModel>().isLoading) return;

  setState(() {
    _imagenSeleccionada = null;
    _imagenBytes = null;
    _mensaje = null;
    _error = false;
  });
}

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalysisViewModel>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              children: [
                const Text(
                  'Nueva muestra',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: texto,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Carga una microfotografía para analizar',
                  style: TextStyle(fontSize: 12, color: secundario),
                ),
                const SizedBox(height: 32),

                Container(
                  height: 188,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: fondoImagen,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagenBytes != null
                      ? Image.memory(
                          _imagenBytes!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              const _IlustracionMicroscopio(),
                        )
                      : const _IlustracionMicroscopio(),
                ),

                if (_imagenSeleccionada != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        color: azul,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _imagenSeleccionada!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: texto, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        onPressed: viewModel.isLoading ? null : _quitarImagen,
                        icon: const Icon(Icons.close, size: 19),
                        tooltip: 'Quitar imagen',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  'Puedes tomar una foto desde el módulo óptico o '
                  'seleccionar una imagen de tu galería.',
                  style: TextStyle(
                    fontSize: 12,
                    color: secundario,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: viewModel.isLoading ? null : _tomarFotografia,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Tomar fotografía'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azul,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: azul.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 45,
                  child: OutlinedButton.icon(
                    onPressed: viewModel.isLoading ? null : _seleccionarImagen,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 19,
                    ),
                    label: const Text('Seleccionar imagen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF303846),
                      side: const BorderSide(color: Color(0xFFE0E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                if (_imagenSeleccionada != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isLoading ? null : _subirImagen,
                      icon: viewModel.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.science_outlined),
                      label: Text(
                        viewModel.isLoading
                            ? 'Procesando imagen...'
                            : 'Analizar imagen',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azul,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: celeste,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recomendación',
                        style: TextStyle(
                          color: azul,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Usa una imagen enfocada, con buena iluminación '
                        'y sin reflejos para mejorar la detección.',
                        style: TextStyle(
                          color: Color(0xFF344454),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_mensaje != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _error
                          ? const Color(0xFFFFEEEE)
                          : const Color(0xFFE9F8EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      _mensaje!,
                      style: TextStyle(
                        color: _error
                            ? Colors.red.shade900
                            : Colors.green.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IlustracionMicroscopio extends StatelessWidget {
  const _IlustracionMicroscopio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 124,
        height: 124,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFDDE1D5),
        ),
        child: const Stack(
          children: [
            _Punto(x: 37, y: 35, color: Color(0xFF1680F5), size: 10),
            _Punto(x: 94, y: 28, color: Color(0xFF19AA82), size: 8),
            _Punto(x: 73, y: 60, color: Color(0xFFEF4C50), size: 7),
            _Punto(x: 25, y: 68, color: Color(0xFFFFB21A), size: 5),
            _Punto(x: 53, y: 86, color: Color(0xFF183653), size: 6),
            _Punto(x: 87, y: 94, color: Color(0xFF35A4F5), size: 8),
          ],
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  final double x;
  final double y;
  final double size;
  final Color color;

  const _Punto({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
