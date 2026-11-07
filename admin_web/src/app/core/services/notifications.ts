import { computed, Injectable, signal } from '@angular/core';

import { catchError, firstValueFrom, of } from 'rxjs';

import { Admin, DashboardAdmin, MuestraAdmin } from './admin';

export type AdminNotificationKind = 'analysis' | 'model';

export interface AdminNotification {
  id: string;

  title: string;

  message: string;

  kind: AdminNotificationKind;

  createdAt: Date | null;

  read: boolean;

  targetPath: string;
}

const READ_STORAGE_KEY = 'microplastia.admin.notifications.read';

const MAX_ANALYSIS_NOTIFICATIONS = 8;

@Injectable({
  providedIn: 'root',
})
export class NotificationsService {
  readonly items = signal<AdminNotification[]>([]);

  readonly loading = signal(false);

  readonly error = signal<string | null>(null);

  readonly unreadCount = computed(() => this.items().filter((item) => !item.read).length);

  constructor(private admin: Admin) {}

  async load(): Promise<void> {
    this.loading.set(true);

    this.error.set(null);

    try {
      const [dashboard, muestras] = await Promise.all([
        firstValueFrom(this.admin.obtenerDashboard().pipe(catchError(() => of(null)))),

        firstValueFrom(
          this.admin.obtenerMuestras().pipe(catchError(() => of([] as MuestraAdmin[]))),
        ),
      ]);

      const readIds = this.readIds();

      const notifications = this.buildNotifications(dashboard, muestras);

      this.items.set(
        notifications.map((item) => ({
          ...item,
          read: readIds.has(item.id),
        })),
      );
    } catch {
      this.error.set('No se pudieron cargar las notificaciones.');
    } finally {
      this.loading.set(false);
    }
  }

  markAllAsRead(): void {
    this.items.update((items) =>
      items.map((item) => ({
        ...item,
        read: true,
      })),
    );

    this.persistReadIds(this.items().map((item) => item.id));
  }

  markAsRead(id: string): void {
    this.items.update((items) =>
      items.map((item) => (item.id === id ? { ...item, read: true } : item)),
    );

    this.persistReadIds(
      this.items()
        .filter((item) => item.read)
        .map((item) => item.id),
    );
  }

  buildNotifications(
    dashboard: DashboardAdmin | null,
    muestras: MuestraAdmin[],
  ): AdminNotification[] {
    const notifications: AdminNotification[] = [];

    if (dashboard && !dashboard.modelo_operativo) {
      notifications.push({
        id: 'model-unavailable',

        title: 'Modelo de IA no disponible',

        message:
          `El modelo ${dashboard.modelo_activo} ` +
          'no está operativo. Revisa el estado del servicio.',

        kind: 'model',

        createdAt: new Date(),

        read: false,

        targetPath: '/dashboard',
      });
    }

    if (dashboard?.alerta_fallback) {
      notifications.push({
        id: 'model-fallback',

        title: 'Uso elevado del modelo local',

        message:
          `${dashboard.porcentaje_fallback}% de los ` +
          'análisis usó el modelo local. Revisa la ' +
          'sincronización del modelo TFLite.',

        kind: 'model',

        createdAt: new Date(),

        read: false,

        targetPath: '/dashboard',
      });
    }

    const recientes = [...muestras]
      .sort((a, b) => {
        const fechaA = this.parseDate(a.fecha)?.getTime() ?? 0;

        const fechaB = this.parseDate(b.fecha)?.getTime() ?? 0;

        return fechaB - fechaA;
      })
      .slice(0, MAX_ANALYSIS_NOTIFICATIONS);

    for (const muestra of recientes) {
      notifications.push({
        id: `analysis-${muestra.id_muestra}`,

        title: 'Análisis completado',

        message:
          `${muestra.codigo} · ` +
          `${muestra.total_particulas} partículas · ` +
          `${muestra.usuario}`,

        kind: 'analysis',

        createdAt: this.parseDate(muestra.fecha),

        read: false,

        targetPath: '/muestras',
      });
    }

    return notifications.sort((a, b) => {
      const fechaA = a.createdAt?.getTime() ?? 0;

      const fechaB = b.createdAt?.getTime() ?? 0;

      return fechaB - fechaA;
    });
  }

  private parseDate(value: string | null | undefined): Date | null {
    if (!value) return null;

    const date = new Date(value);

    return Number.isNaN(date.getTime()) ? null : date;
  }

  private readIds(): Set<string> {
    if (typeof localStorage === 'undefined') {
      return new Set();
    }

    try {
      const raw = localStorage.getItem(READ_STORAGE_KEY);

      if (!raw) return new Set();

      const parsed: unknown = JSON.parse(raw);

      return Array.isArray(parsed)
        ? new Set(parsed.filter((id): id is string => typeof id === 'string'))
        : new Set();
    } catch {
      return new Set();
    }
  }

  private persistReadIds(ids: string[]): void {
    if (typeof localStorage === 'undefined') {
      return;
    }

    try {
      localStorage.setItem(READ_STORAGE_KEY, JSON.stringify([...new Set(ids)]));
    } catch {
      // El almacenamiento local puede no estar disponible.
    }
  }
}
