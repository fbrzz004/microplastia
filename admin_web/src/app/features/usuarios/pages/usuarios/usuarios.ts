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
  UsuarioAdmin
} from '../../../../core/services/admin';


@Component({
  selector: 'app-usuarios',

  standalone: true,

  imports: [
    CommonModule
  ],

  templateUrl:
    './usuarios.html',

  styleUrl:
    './usuarios.css'
})
export class Usuarios implements OnInit {

  usuarios:
    UsuarioAdmin[] = [];

  cargando = true;

  error = '';


  constructor(
    private adminService: Admin,

    private cdr:
      ChangeDetectorRef
  ) {}


  ngOnInit(): void {
    this.cargarUsuarios();
  }


  cargarUsuarios(): void {

    this.cargando = true;

    this.error = '';


    this.adminService
      .obtenerUsuarios()
      .pipe(

        finalize(() => {

          this.cargando = false;

          this.cdr.markForCheck();

        })

      )
      .subscribe({

        next: (
          usuarios
        ) => {

          this.usuarios = usuarios;

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
        'No se pudieron cargar los usuarios.'
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
          + 'consultar los usuarios.'
        );


      case 429:

        return (
          'Se realizaron demasiadas solicitudes. '
          + 'Inténtalo nuevamente más tarde.'
        );


      case 500:

        return (
          'Ocurrió un problema al cargar '
          + 'los usuarios.'
        );


      case 503:

        return (
          'El servicio no está disponible '
          + 'temporalmente.'
        );


      default:

        return (
          'No se pudieron cargar los usuarios.'
        );
    }
  }
}