import {
  ChangeDetectorRef,
  Component,
  OnInit
} from '@angular/core';

import {
  CommonModule
} from '@angular/common';

import {
  FormsModule
} from '@angular/forms';

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
    CommonModule,
    FormsModule
  ],

  templateUrl:
    './usuarios.html',

  styleUrl:
    './usuarios.css'
})
export class Usuarios implements OnInit {

  usuarios:
    UsuarioAdmin[] = [];

  busqueda = '';

  estadoFiltro = '';

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


 get usuariosFiltrados():
  UsuarioAdmin[] {

  const terminoOriginal =
    this.busqueda.trim();

  const termino =
    this.normalizarTexto(
      terminoOriginal
    );

  const coincidenciaId =
    terminoOriginal.match(
      /^(?:id\s*)?#?\s*(\d+)$/i
    );

  const idBuscado =
    coincidenciaId
      ? Number(
          coincidenciaId[1]
        )
      : null;


  return this.usuarios.filter(
    usuario => {

      if (
        idBuscado !== null
      ) {

        const coincideEstado =
          !this.estadoFiltro
          || (
            this.estadoFiltro === 'Activo'
            && usuario.estado
          )
          || (
            this.estadoFiltro === 'Inactivo'
            && !usuario.estado
          );

        return (
          usuario.id_usuario
          === idBuscado
        )
        && coincideEstado;
      }


      const nombreCompleto =
        `${usuario.nombre} `
        + `${usuario.apellido ?? ''}`;

      const coincideBusqueda =
        !termino
        || this.normalizarTexto(
          nombreCompleto
        ).includes(
          termino
        )
        || this.normalizarTexto(
          usuario.correo
        ).includes(
          termino
        );


      const coincideEstado =
        !this.estadoFiltro
        || (
          this.estadoFiltro === 'Activo'
          && usuario.estado
        )
        || (
          this.estadoFiltro === 'Inactivo'
          && !usuario.estado
        );


      return (
        coincideBusqueda
        && coincideEstado
      );
    }
  );
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


  limpiarFiltros(): void {

    this.busqueda = '';

    this.estadoFiltro = '';
  }


  private normalizarTexto(
    valor: string
  ): string {

    return valor
      .normalize('NFD')
      .replace(
        /[\u0300-\u036f]/g,
        ''
      )
      .trim()
      .toLowerCase();
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
