import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import { CommonModule } from '@angular/common';

import {
  Admin,
  MuestraAdmin
} from '../../../../core/services/admin';

@Component({
  selector: 'app-muestras',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './muestras.html',
  styleUrl: './muestras.css'
})
export class Muestras implements OnInit {

  muestras: MuestraAdmin[] = [];

  cargando = true;
  error = '';

  constructor(
    private adminService: Admin,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarMuestras();
  }

  cargarMuestras(): void {

    this.cargando = true;
    this.error = '';

    this.adminService.obtenerMuestras().subscribe({

      next: (muestras) => {

        this.muestras = muestras;

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
            'No tienes permisos para consultar las muestras.';
        } else {
          this.error =
            'No se pudieron cargar las muestras.';
        }

        this.cdr.markForCheck();

        console.error(
          'Error al cargar muestras:',
          error
        );
      }
    });
  }
}