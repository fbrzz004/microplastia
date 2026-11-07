import { computed, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { AdminNotification, NotificationsService } from '../../../core/services/notifications';
import { Header } from './header';

const notificationsStub = {
  items: signal<AdminNotification[]>([]),
  loading: signal(false),
  error: signal<string | null>(null),
  unreadCount: computed(() => 0),
  load: async () => undefined,
  markAllAsRead: () => undefined,
  markAsRead: () => undefined,
};

describe('Header', () => {
  let component: Header;
  let fixture: ComponentFixture<Header>;

  beforeEach(async () => {
    notificationsStub.items.set([]);
    notificationsStub.loading.set(false);
    notificationsStub.error.set(null);

    await TestBed.configureTestingModule({
      imports: [Header],
      providers: [
        provideRouter([]),
        { provide: NotificationsService, useValue: notificationsStub },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(Header);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('muestra el botón de notificaciones y abre el panel', async () => {
    const button = fixture.nativeElement.querySelector('.notification-button') as HTMLButtonElement;

    expect(button).toBeTruthy();
    expect(button.getAttribute('aria-label')).toBe('Notificaciones');

    button.click();
    fixture.detectChanges();
    await fixture.whenStable();

    expect(fixture.nativeElement.querySelector('.notifications-panel')).toBeTruthy();
    expect(fixture.nativeElement.textContent).toContain('No hay notificaciones');
  });
});
