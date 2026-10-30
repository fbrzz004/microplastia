import {
  ChangeDetectorRef,
  Component
} from '@angular/core';

import {
  FormsModule
} from '@angular/forms';

import {
  Router
} from '@angular/router';

import {
  HttpErrorResponse
} from '@angular/common/http';

import {
  finalize
} from 'rxjs';

import {
  Auth
} from '../../../../core/services/auth';


@Component({
  selector: 'app-login',

  standalone: true,

  imports: [
    FormsModule
  ],

  templateUrl:
    './login.html',

  styleUrl:
    './login.css'
})
export class Login {

  correo = '';

  password = '';

  mantenerSesion = false;

  mostrarPassword = false;

  cargando = false;

  error = '';


  constructor(
    private authService: Auth,

    private router: Router,

    private cdr:
      ChangeDetectorRef
  ) {}


  iniciarSesion(): void {

    if (this.cargando) {
      return;
    }


    this.error = '';


    const correo =
      this.correo
        .trim()
        .toLowerCase();


    if (
      !correo ||
      !this.password
    ) {

      this.error =
        'Ingresa tu correo y contraseña.';

      this.cdr.markForCheck();

      return;
    }


    if (
      !this.correoValido(
        correo
      )
    ) {

      this.error =
        'Ingresa un correo electrónico válido.';

      this.cdr.markForCheck();

      return;
    }


    this.cargando = true;

    this.cdr.markForCheck();


    this.authService
      .login(
        correo,
        this.password
      )
      .pipe(

        finalize(() => {

          this.cargando = false;

          this.cdr.markForCheck();

        })

      )
      .subscribe({

        next: (
          respuesta
        ) => {

          // ================================================
          // SOLO ADMINISTRADORES
          // ================================================

          if (
            respuesta.usuario.rol !==
              'administrador' ||
            respuesta.usuario.estado !==
              true
          ) {

            this.authService
              .limpiarSesion();


            this.error =
              'No tienes permisos para acceder '
              + 'al panel administrativo.';


            this.cdr.markForCheck();

            return;
          }


          // ================================================
          // GUARDAR SESIÓN
          // ================================================

          this.authService
            .guardarSesion(
              respuesta,
              this.mantenerSesion
            );


          // ================================================
          // DASHBOARD
          // ================================================

          this.router.navigate(
            ['/dashboard']
          );
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


  private correoValido(
    correo: string
  ): boolean {

    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      .test(correo);
  }


  private obtenerMensajeError(
    error: unknown
  ): string {

    if (
      !(error instanceof
        HttpErrorResponse)
    ) {

      return (
        'No se pudo conectar con el servidor. '
        + 'Inténtalo nuevamente.'
      );
    }


    switch (
      error.status
    ) {

      case 0:

        return (
          'No se pudo conectar con el servidor. '
          + 'Verifica tu conexión.'
        );


      case 401:

        return (
          'Correo o contraseña incorrectos.'
        );


      case 403:

        return (
          'No tienes permisos para acceder '
          + 'al panel administrativo.'
        );


      case 422:

        return (
          'Revisa el correo y la contraseña ingresados.'
        );


      case 429:

        return (
          'Se realizaron demasiados intentos. '
          + 'Inténtalo nuevamente más tarde.'
        );


      case 500:

        return (
          'Ocurrió un problema en el servidor. '
          + 'Inténtalo nuevamente.'
        );


      case 503:

        return (
          'El servicio no está disponible '
          + 'temporalmente.'
        );


      default:

        return (
          'No se pudo iniciar sesión. '
          + 'Inténtalo nuevamente.'
        );
    }
  }
}