import { Component, inject, OnInit, signal } from '@angular/core';

import { Router } from '@angular/router';

import { AdminNotification, NotificationsService } from '../../../core/services/notifications';

@Component({
  selector: 'app-header',

  standalone: true,

  templateUrl: './header.html',

  styleUrl: './header.css',
})
export class Header implements OnInit {
  private readonly notifications = inject(NotificationsService);

  private readonly router = inject(Router);

  readonly notificationsOpen = signal(false);

  readonly items = this.notifications.items;

  readonly loading = this.notifications.loading;

  readonly error = this.notifications.error;

  readonly unreadCount = this.notifications.unreadCount;

  ngOnInit(): void {
    void this.notifications.load();
  }

  toggleNotifications(): void {
    this.notificationsOpen.update((open) => !open);
  }

  closeNotifications(): void {
    this.notificationsOpen.set(false);
  }

  markAllAsRead(): void {
    this.notifications.markAllAsRead();
  }

  openNotification(notification: AdminNotification): void {
    this.notifications.markAsRead(notification.id);

    this.closeNotifications();

    void this.router.navigateByUrl(notification.targetPath);
  }

  formatRelativeDate(value: Date | null): string {
    if (!value) return '';

    const diff = Date.now() - value.getTime();

    if (diff < 60_000) {
      return 'Ahora';
    }

    const minutes = Math.floor(diff / 60_000);

    if (minutes < 60) {
      return `Hace ${minutes} min`;
    }

    const hours = Math.floor(minutes / 60);

    if (hours < 24) {
      return `Hace ${hours} h`;
    }

    const days = Math.floor(hours / 24);

    if (days < 7) {
      return `Hace ${days} d`;
    }

    return value.toLocaleDateString('es-PE', {
      day: '2-digit',
      month: 'short',
    });
  }
}
