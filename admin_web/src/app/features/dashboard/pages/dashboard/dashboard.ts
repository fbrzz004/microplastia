import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import {
  CommonModule
} from '@angular/common';

import {
  HttpErrorResponse
} from '@angular/common/http';

import {
  finalize
} from 'rxjs';

import {
  Admin,
  DashboardAdmin
} from '../../../../core/services/admin';


@Component({
  selector: 'app-dashboard',

  standalone: true,

  imports: [
    CommonModule
  ],

  templateUrl:
    './dashboard.html',

  styleUrl:
    './dashboard.css'
})
export class Dashboard implements OnInit {

  datos:
    DashboardAdmin | null = null;

  cargando = true;

  error = '';


  constructor(
    private adminService: Admin,

    private cdr:
      ChangeDetectorRef
  ) {}


  ngOnInit(): void {
    this.cargarDashboard();
  }


  cargarDashboard(): void {

    if (this.cargando && this.datos) {
      return;
    }


    this.cargando = true;

    this.error = '';


    this.adminService
      .obtenerDashboard()
      .pipe(

        finalize(() => {

          this.cargando = false;

          this.cdr.markForCheck();

        })

      )
      .subscribe({

        next: (
          datos
        ) => {

          this.datos = datos;

          this.error = '';

          this.cdr.markForCheck();
        },


        error: (
          error: unknown
        ) => {

          this.error =
            this.obtenerMensajeError(
              error
            );

          this.cdr.markForCheck();
        }

      });
  }


  private obtenerMensajeError(
    error: unknown
  ): string {

    if (
      !(error instanceof
        HttpErrorResponse)
    ) {

      return (
        'No se pudieron cargar '
        + 'los datos del Dashboard.'
      );
    }


    switch (
      error.status
    ) {

      case 0:

        return (
          'No se pudo conectar con el servidor.'
        );


      case 401:

        return (
          'Tu sesión ha expirado.'
        );


      case 403:

        return (
          'No tienes permisos para '
          + 'consultar el Dashboard.'
        );


      case 429:

        return (
          'Se realizaron demasiadas solicitudes. '
          + 'Inténtalo nuevamente más tarde.'
        );


      case 500:

        return (
          'Ocurrió un problema al cargar '
          + 'el Dashboard.'
        );


      case 503:

        return (
          'El servicio no está disponible '
          + 'temporalmente.'
        );


      default:

        return (
          'No se pudieron cargar '
          + 'los datos del Dashboard.'
        );
    }
  }
}