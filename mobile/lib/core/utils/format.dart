String _dosDigitos(int valor) => valor.toString().padLeft(2, '0');

String formatearFecha(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';

  final local = fecha.toLocal();

  return '${_dosDigitos(local.day)}/'
      '${_dosDigitos(local.month)}/'
      '${local.year}';
}

String formatearFechaHora(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';

  final local = fecha.toLocal();

  return '${formatearFecha(local)} '
      '${_dosDigitos(local.hour)}:'
      '${_dosDigitos(local.minute)}';
}
