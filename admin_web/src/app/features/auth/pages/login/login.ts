import {
  ChangeDetectorRef,
  Component
} from '@angular/core';

import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import { finalize } from 'rxjs';

import { Auth } from '../../../../core/services/auth';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.css'
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
    private cdr: ChangeDetectorRef
  ) {}

  iniciarSesion(): void {

    this.error = '';

    if (!this.correo || !this.password) {
      this.error = 'Ingresa tu correo y contraseña.';
      this.cdr.markForCheck();
      return;
    }

    this.cargando = true;
    this.cdr.markForCheck();

    this.authService
      .login(this.correo, this.password)
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.markForCheck();
        })
      )
      .subscribe({

        next: (respuesta) => {

          if (respuesta.usuario.rol !== 'administrador') {

            this.error =
              'No tienes permisos para acceder al panel administrativo.';

            this.cdr.markForCheck();

            return;
          }

          const almacenamiento = this.mantenerSesion
            ? localStorage
            : sessionStorage;

          almacenamiento.setItem(
            'access_token',
            respuesta.access_token
          );

          almacenamiento.setItem(
            'usuario',
            JSON.stringify(respuesta.usuario)
          );

          this.router.navigate(['/dashboard']);
        },

        error: (error) => {

          if (error.status === 401) {

            this.error =
              'Correo o contraseña incorrectos.';

          } else if (error.status === 422) {

            this.error =
              'Ingresa un correo electrónico válido.';

          } else if (error.status === 403) {

            this.error =
              'No tienes permisos para acceder al panel administrativo.';

          } else {

            this.error =
              'No se pudo iniciar sesión. Inténtalo nuevamente.';
          }

          this.cdr.markForCheck();

          console.error(
            'Error al iniciar sesión:',
            error
          );
        }
      });
  }
}