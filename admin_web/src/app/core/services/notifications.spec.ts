import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { Admin, DashboardAdmin, MuestraAdmin } from './admin';
import { NotificationsService } from './notifications';

const dashboard: DashboardAdmin = {
  muestras_analizadas: 3,
  particulas_detectadas: 42,
  usuarios_registrados: 2,
  modelo_activo: 'best.tflite',
  modelo_operativo: true,
  resolucion_inferencia: 640,
  umbral_confianza: 0.25,
  numero_clases: 4,
  tiempo_promedio_inferencia_ms: 120,
  ultima_inferencia_ms: 110,
  distribucion: {
    fibra: 1,
    fragmento: 1,
    gránulo: 1,
    película: 0,
  },
  analisis_con_modelo: 3,
  uso_downloaded: 3,
  uso_fallback: 0,
  porcentaje_downloaded: 100,
  porcentaje_fallback: 0,
  alerta_fallback: false,
};

const muestras: MuestraAdmin[] = [
  {
    id_muestra: 1,
    codigo: 'MUESTRA-1',
    usuario: 'Ana',
    correo: 'ana@example.com',
    fecha: '2026-11-05T10:00:00Z',
    total_particulas: 10,
    confianza_promedio: 0.9,
    estado: 'analizada',
    modelo_nombre: 'best.tflite',
    modelo_version: '1.0',
    modelo_origen: 'descargado',
  },
  {
    id_muestra: 2,
    codigo: 'MUESTRA-2',
    usuario: 'Luis',
    correo: 'luis@example.com',
    fecha: '2026-11-06T10:00:00Z',
    total_particulas: 20,
    confianza_promedio: 0.8,
    estado: 'analizada',
    modelo_nombre: 'best.tflite',
    modelo_version: '1.0',
    modelo_origen: 'descargado',
  },
];

class FakeAdmin {
  dashboard: DashboardAdmin = dashboard;
  muestras: MuestraAdmin[] = muestras;

  obtenerDashboard() {
    return of(this.dashboard);
  }

  obtenerMuestras() {
    return of(this.muestras);
  }
}

describe('NotificationsService', () => {
  let service: NotificationsService;
  let admin: FakeAdmin;

  beforeEach(() => {
    localStorage.clear();
    admin = new FakeAdmin();

    TestBed.configureTestingModule({
      providers: [NotificationsService, { provide: Admin, useValue: admin }],
    });

    service = TestBed.inject(NotificationsService);
  });

  it('crea una notificación por análisis, de más reciente a más antiguo', async () => {
    await service.load();

    expect(service.items().length).toBe(2);
    expect(service.items()[0].message).toContain('MUESTRA-2');
    expect(service.items()[1].message).toContain('MUESTRA-1');
    expect(service.unreadCount()).toBe(2);
  });

  it('agrega una notificación cuando el modelo no está operativo', async () => {
    admin.dashboard = {
      ...dashboard,
      modelo_operativo: false,
    };

    await service.load();

    expect(service.items().some((item) => item.kind === 'model')).toBe(true);
  });

  it('avisa cuando el uso del modelo local es elevado', async () => {
    admin.dashboard = {
      ...dashboard,
      alerta_fallback: true,
      porcentaje_fallback: 65,
    };

    await service.load();

    const notification = service.items().find((item) => item.id === 'model-fallback');

    expect(notification).toBeTruthy();
    expect(notification?.message).toContain('65%');
  });

  it('marca todas las notificaciones como leídas y las conserva así', async () => {
    await service.load();
    service.markAllAsRead();

    expect(service.unreadCount()).toBe(0);

    await service.load();

    expect(service.unreadCount()).toBe(0);
  });
});
