import { computed, Injectable, signal } from '@angular/core';

import { firstValueFrom } from 'rxjs';

import { Admin, AdminNotificationItem } from './admin';

export type AdminNotificationKind = 'analysis' | 'model';

export interface AdminNotification {
  id: number;

  title: string;

  message: string;

  kind: AdminNotificationKind;

  createdAt: Date | null;

  read: boolean;

  targetPath: string;
}

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
      const response = await firstValueFrom(this.admin.obtenerNotificaciones());

      this.items.set(response.data.items.map((item) => this.toNotification(item)));
    } catch {
      this.error.set('No se pudieron cargar las notificaciones.');
    } finally {
      this.loading.set(false);
    }
  }

  async markAllAsRead(): Promise<void> {
    if (this.items().length === 0) return;

    try {
      await firstValueFrom(this.admin.marcarTodasNotificacionesLeidas());

      this.items.update((items) =>
        items.map((item) => ({
          ...item,
          read: true,
        })),
      );
    } catch {
      this.error.set('No se pudieron marcar las notificaciones.');
    }
  }

  async markAsRead(id: number): Promise<void> {
    const notification = this.items().find((item) => item.id === id);

    if (!notification || notification.read) return;

    try {
      await firstValueFrom(this.admin.marcarNotificacionLeida(id));

      this.items.update((items) =>
        items.map((item) => (item.id === id ? { ...item, read: true } : item)),
      );
    } catch {
      this.error.set('No se pudo marcar la notificación.');
    }
  }

  private toNotification(item: AdminNotificationItem): AdminNotification {
    return {
      id: item.id,

      title: item.title,

      message: item.message,

      kind: item.type === 'model' ? 'model' : 'analysis',

      createdAt: this.parseDate(item.created_at),

      read: item.is_read,

      targetPath: item.type === 'model' ? '/dashboard' : '/muestras',
    };
  }

  private parseDate(value: string | null | undefined): Date | null {
    if (!value) return null;

    const date = new Date(value);

    return Number.isNaN(date.getTime()) ? null : date;
  }
}
