import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/services/profile_service.dart';
import 'package:mobile/viewmodels/profile_viewmodel.dart';

class _FakeProfileService extends ProfileService {
  _FakeProfileService({
    this.fail = false,
  });

  final bool fail;

  bool? updatedValue;

  @override
  Future<bool> getNotificationsEnabled() async => true;

  @override
  Future<void> updateNotificationsEnabled(bool enabled) async {
    if (fail) {
      throw Exception('fallo de red');
    }

    updatedValue = enabled;
  }
}

void main() {
  test('guarda la preferencia de notificaciones en el servidor', () async {
    final service = _FakeProfileService();
    final viewModel = ProfileViewModel(
      profileService: service,
    );

    await viewModel.setNotifications(false);

    expect(viewModel.notificacionesActivas, isFalse);
    expect(service.updatedValue, isFalse);
    expect(viewModel.errorMessage, isNull);
  });

  test('revierte la preferencia si el servidor falla', () async {
    final service = _FakeProfileService(fail: true);
    final viewModel = ProfileViewModel(
      profileService: service,
    );

    await viewModel.setNotifications(false);

    expect(viewModel.notificacionesActivas, isTrue);
    expect(viewModel.errorMessage, isNotNull);
  });
}
