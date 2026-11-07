import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/format.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../viewmodels/notifications_viewmodel.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({
    super.key,
    this.notificationService,
  });

  final NotificationService? notificationService;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  static const Color azul = Color(0xFF1976E9);
  static const Color oscuro = Color(0xFF203653);

  late final NotificationsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = NotificationsViewModel(
      service: widget.notificationService,
    );
    _viewModel.load();
  }

  Future<void> _openNotification(
    AppNotification item,
  ) async {
    await _viewModel.markAsRead(item);

    if (!mounted) return;

    final analysisId = item.analysisId;

    if (analysisId != null) {
      context.go('/history/$analysisId');
      return;
    }

    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Volver',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: oscuro,
                size: 19,
              ),
            ),
            title: const Text(
              'Notificaciones',
              style: TextStyle(
                color: oscuro,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (_viewModel.unreadCount > 0)
                TextButton(
                  onPressed: _viewModel.markAllAsRead,
                  child: const Text(
                    'Marcar leídas',
                    style: TextStyle(
                      color: azul,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _body(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body() {
    if (_viewModel.isLoading && _viewModel.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: azul),
      );
    }

    if (_viewModel.errorMessage != null && _viewModel.items.isEmpty) {
      return _EstadoNotificaciones(
        icono: Icons.cloud_off_outlined,
        titulo: 'No se pudieron cargar',
        mensaje: _viewModel.errorMessage!,
        accion: 'Reintentar',
        onTap: _viewModel.load,
      );
    }

    if (_viewModel.items.isEmpty) {
      return _EstadoNotificaciones(
        icono: Icons.notifications_none_rounded,
        titulo: 'No tienes notificaciones',
        mensaje: 'Los resultados de tus análisis aparecerán aquí.',
        accion: 'Actualizar',
        onTap: _viewModel.load,
      );
    }

    return RefreshIndicator(
      onRefresh: _viewModel.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        itemCount: _viewModel.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _viewModel.items[index];

          return _NotificationTile(
            item: item,
            onTap: () => _openNotification(item),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final AppNotification item;
  final VoidCallback onTap;

  static const Color azul = Color(0xFF1976E9);
  static const Color oscuro = Color(0xFF203653);
  static const Color gris = Color(0xFF8290A5);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.read ? Colors.white : const Color(0xFFF2F7FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  item.read ? const Color(0xFFE0E8F3) : const Color(0xFFCFE1FF),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F1FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: azul,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: oscuro,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!item.read)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: azul,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        color: Color(0xFF687B98),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatearFechaHora(item.createdAt),
                      style: const TextStyle(
                        color: gris,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9AABC0),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoNotificaciones extends StatelessWidget {
  const _EstadoNotificaciones({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.accion,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final String accion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 24),
      children: [
        Center(
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icono,
              color: const Color(0xFF7D9AC0),
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF203653),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8290A5),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: onTap,
            child: Text(accion),
          ),
        ),
      ],
    );
  }
}
