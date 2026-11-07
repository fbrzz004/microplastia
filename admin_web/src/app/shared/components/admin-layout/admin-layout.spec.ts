import { computed, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { AdminNotification, NotificationsService } from '../../../core/services/notifications';
import { AdminLayout } from './admin-layout';

const notificationsStub = {
  items: signal<AdminNotification[]>([]),
  loading: signal(false),
  error: signal<string | null>(null),
  unreadCount: computed(() => 0),
  load: async () => undefined,
  markAllAsRead: () => undefined,
  markAsRead: () => undefined,
};

describe('AdminLayout', () => {
  let component: AdminLayout;
  let fixture: ComponentFixture<AdminLayout>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AdminLayout],
      providers: [
        provideRouter([]),
        { provide: NotificationsService, useValue: notificationsStub },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(AdminLayout);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
