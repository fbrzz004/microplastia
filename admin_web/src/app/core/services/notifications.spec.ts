import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { Admin, AdminNotificationItem } from './admin';
import { NotificationsService } from './notifications';

const notifications: AdminNotificationItem[] = [
  {
    id: 2,
    type: 'analysis',
    title: 'Análisis completado',
    message: 'MUESTRA-2 · 20 partículas · Luis',
    result_id: 10,
    is_read: false,
    created_at: '2026-11-06T10:00:00Z',
  },
  {
    id: 1,
    type: 'model',
    title: 'Uso elevado del modelo local',
    message: '65% de los análisis usó el modelo local.',
    result_id: null,
    is_read: true,
    created_at: '2026-11-05T10:00:00Z',
  },
];

class FakeAdmin {
  items: AdminNotificationItem[] = notifications.map((item) => ({ ...item }));

  readCalls: number[] = [];

  readAllCalls = 0;

  obtenerNotificaciones() {
    return of({
      success: true,
      data: {
        items: this.items,
        total: this.items.length,
        unread_count: this.items.filter((item) => !item.is_read).length,
        limit: 20,
        offset: 0,
      },
    });
  }

  marcarNotificacionLeida(id: number) {
    this.readCalls.push(id);

    const item = this.items.find((notification) => notification.id === id);

    if (item) {
      item.is_read = true;
    }

    return of({
      success: true,
      data: item,
    });
  }

  marcarTodasNotificacionesLeidas() {
    this.readAllCalls++;

    this.items = this.items.map((item) => ({
      ...item,
      is_read: true,
    }));

    return of(undefined);
  }
}

describe('NotificationsService', () => {
  let service: NotificationsService;
  let admin: FakeAdmin;

  beforeEach(() => {
    admin = new FakeAdmin();

    TestBed.configureTestingModule({
      providers: [NotificationsService, { provide: Admin, useValue: admin }],
    });

    service = TestBed.inject(NotificationsService);
  });

  it('carga las notificaciones desde el servidor', async () => {
    await service.load();

    expect(service.items().length).toBe(2);
    expect(service.items()[0].title).toBe('Análisis completado');
    expect(service.items()[0].targetPath).toBe('/muestras');
    expect(service.items()[0].read).toBe(false);
    expect(service.unreadCount()).toBe(1);
  });

  it('asigna dashboard como destino de una alerta de modelo', async () => {
    await service.load();

    expect(service.items()[1].kind).toBe('model');
    expect(service.items()[1].targetPath).toBe('/dashboard');
  });

  it('marca una notificación como leída en el servidor', async () => {
    await service.load();

    await service.markAsRead(2);

    expect(admin.readCalls).toEqual([2]);
    expect(service.unreadCount()).toBe(0);
    expect(service.items()[0].read).toBe(true);
  });

  it('marca todas las notificaciones como leídas en el servidor', async () => {
    await service.load();

    await service.markAllAsRead();

    expect(admin.readAllCalls).toBe(1);
    expect(service.unreadCount()).toBe(0);
  });
});
