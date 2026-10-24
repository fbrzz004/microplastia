import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';

import {
  Admin,
  DashboardAdmin
} from '../../../../core/services/admin';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css'
})
export class Dashboard implements OnInit {

  datos: DashboardAdmin | null = null;

  cargando = true;
  error = '';

  constructor(
    private adminService: Admin,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarDashboard();
  }

  cargarDashboard(): void {

    this.cargando = true;
    this.error = '';

    this.adminService.obtenerDashboard().subscribe({

      next: (datos) => {

        this.datos = datos;

        this.cargando = false;

        this.cdr.markForCheck();
      },

      error: (error) => {

        this.cargando = false;

        if (error.status === 401) {
          this.error =
            'Tu sesión ha expirado. Vuelve a iniciar sesión.';
        } else if (error.status === 403) {
          this.error =
            'No tienes permisos para consultar el Dashboard.';
        } else {
          this.error =
            'No se pudieron cargar los datos del Dashboard.';
        }

        this.cdr.markForCheck();

        console.error(
          'Error al cargar Dashboard:',
          error
        );
      }
    });
  }
}