import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';

import {
  Admin,
  UsuarioAdmin
} from '../../../../core/services/admin';

@Component({
  selector: 'app-usuarios',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './usuarios.html',
  styleUrl: './usuarios.css'
})
export class Usuarios implements OnInit {

  usuarios: UsuarioAdmin[] = [];

  cargando = true;
  error = '';

  constructor(
    private adminService: Admin,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarUsuarios();
  }

  cargarUsuarios(): void {

    this.cargando = true;
    this.error = '';

    this.adminService.obtenerUsuarios().subscribe({

      next: (usuarios) => {

        this.usuarios = usuarios;

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
            'No tienes permisos para consultar los usuarios.';

        } else {

          this.error =
            'No se pudieron cargar los usuarios.';
        }

        this.cdr.markForCheck();

        console.error(
          'Error al cargar usuarios:',
          error
        );
      }
    });
  }
}