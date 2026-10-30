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
  MuestraAdmin
} from '../../../../core/services/admin';


@Component({
  selector: 'app-muestras',

  standalone: true,

  imports: [
    CommonModule
  ],

  templateUrl:
    './muestras.html',

  styleUrl:
    './muestras.css'
})
export class Muestras implements OnInit {

  muestras:
    MuestraAdmin[] = [];

  cargando = true;

  error = '';


  constructor(
    private adminService: Admin,

    private cdr:
      ChangeDetectorRef
  ) {}


  ngOnInit(): void {
    this.cargarMuestras();
  }


  cargarMuestras(): void {

    this.cargando = true;

    this.error = '';


    this.adminService
      .obtenerMuestras()
      .pipe(

        finalize(() => {

          this.cargando = false;

          this.cdr.markForCheck();

        })

      )
      .subscribe({

        next: (
          muestras
        ) => {

          this.muestras = muestras;

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
        'No se pudieron cargar las muestras.'
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
          + 'consultar las muestras.'
        );


      case 429:

        return (
          'Se realizaron demasiadas solicitudes. '
          + 'Inténtalo nuevamente más tarde.'
        );


      case 500:

        return (
          'Ocurrió un problema al cargar '
          + 'las muestras.'
        );


      case 503:

        return (
          'El servicio no está disponible '
          + 'temporalmente.'
        );


      default:

        return (
          'No se pudieron cargar las muestras.'
        );
    }
  }
}