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
  MuestraAdmin
} from '../../../../core/services/admin';

import {
  API_CONFIG
} from '../../../../core/config/api-config';


@Component({
  selector: 'app-muestras',

  standalone: true,

  imports: [
    CommonModule,
    FormsModule
  ],

  templateUrl:
    './muestras.html',

  styleUrl:
    './muestras.css'
})
export class Muestras implements OnInit {

  muestras:
    MuestraAdmin[] = [];

  busqueda = '';

  estadoFiltro = '';

  fechaDesde = '';

  fechaHasta = '';

  cargando = true;

  generandoReporte = false;

  error = '';

  errorReporte = '';

  mensajeReporte = '';


  constructor(
    private adminService: Admin,

    private cdr:
      ChangeDetectorRef
  ) {}


  ngOnInit(): void {
    this.cargarMuestras();
  }


  get rangoFechasInvalido(): boolean {

    return (
      !!this.fechaDesde
      && !!this.fechaHasta
      && this.fechaDesde
        > this.fechaHasta
    );
  }


  get muestrasFiltradas():
    MuestraAdmin[] {

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


    return this.muestras.filter(
      muestra => {

        const coincideEstado =
          !this.estadoFiltro
          || muestra.estado
            === this.estadoFiltro;

        const fechaMuestra =
          this.obtenerFechaLocalISO(
            muestra.fecha
          );

        const coincideFechaDesde =
          !this.fechaDesde
          || fechaMuestra
            >= this.fechaDesde;

        const coincideFechaHasta =
          !this.fechaHasta
          || fechaMuestra
            <= this.fechaHasta;

        const coincideFechas =
          coincideFechaDesde
          && coincideFechaHasta;


        if (
          idBuscado !== null
        ) {

          return (
            muestra.id_muestra
            === idBuscado
          )
          && coincideEstado
          && coincideFechas;
        }


        const coincideBusqueda =
          !termino
          || this.normalizarTexto(
            muestra.codigo
          ).includes(
            termino
          )
          || this.normalizarTexto(
            muestra.usuario
          ).includes(
            termino
          )
          || this.normalizarTexto(
            muestra.correo
          ).includes(
            termino
          )
          || this.normalizarTexto(
            this.formatearFecha(
              muestra.fecha
            )
          ).includes(
            termino
          );


        return (
          coincideBusqueda
          && coincideEstado
          && coincideFechas
        );
      }
    );
  }


  get analisisFiltradosReporte():
    MuestraAdmin[] {

    return this.muestrasFiltradas.filter(
      muestra =>
        muestra.estado === 'Analizada'
        && muestra.id_resultado !== null
    );
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


  limpiarFiltros(): void {

    this.busqueda = '';

    this.estadoFiltro = '';

    this.fechaDesde = '';

    this.fechaHasta = '';

    this.errorReporte = '';

    this.mensajeReporte = '';
  }


  generarReporte(): void {

    this.errorReporte = '';

    this.mensajeReporte = '';


    if (
      this.rangoFechasInvalido
    ) {

      this.errorReporte =
        'La fecha "Desde" no puede ser '
        + 'posterior a la fecha "Hasta".';

      return;
    }


    const ids =
      this.analisisFiltradosReporte
        .map(
          muestra =>
            muestra.id_resultado
        )
        .filter(
          (
            id
          ): id is number =>
            id !== null
        );


    if (
      ids.length === 0
    ) {

      this.errorReporte =
        'No hay muestras analizadas '
        + 'en los filtros actuales para '
        + 'generar el reporte.';

      return;
    }


    if (
      ids.length > 200
    ) {

      this.errorReporte =
        'El reporte admite como máximo '
        + '200 análisis. Aplica más filtros '
        + 'antes de generarlo.';

      return;
    }


    this.generandoReporte = true;


    this.adminService
      .generarReporte(
        ids
      )
      .pipe(

        finalize(() => {

          this.generandoReporte = false;

          this.cdr.markForCheck();

        })

      )
      .subscribe({

        next: (
          respuesta
        ) => {

          this.mensajeReporte =
            respuesta.message;

          const urlReporte =
            `${API_CONFIG.baseUrl}`
            + respuesta.data.report_url;

          window.open(
            urlReporte,
            '_blank',
            'noopener,noreferrer'
          );

          this.cdr.markForCheck();
        },


        error: (
          error: unknown
        ) => {

          this.errorReporte =
            this.obtenerMensajeErrorReporte(
              error
            );

          this.cdr.markForCheck();
        }

      });
  }


  private obtenerFechaLocalISO(
    fecha: string
  ): string {

    const valor =
      new Date(
        fecha
      );

    if (
      Number.isNaN(
        valor.getTime()
      )
    ) {

      return '';
    }


    const year =
      valor.getFullYear();

    const month =
      String(
        valor.getMonth() + 1
      ).padStart(
        2,
        '0'
      );

    const day =
      String(
        valor.getDate()
      ).padStart(
        2,
        '0'
      );


    return (
      `${year}-${month}-${day}`
    );
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


  private formatearFecha(
    fecha: string
  ): string {

    const valor =
      new Date(
        fecha
      );

    if (
      Number.isNaN(
        valor.getTime()
      )
    ) {

      return fecha;
    }

    return valor.toLocaleDateString(
      'es-PE'
    );
  }


  private obtenerMensajeErrorReporte(
    error: unknown
  ): string {

    if (
      !(error instanceof
        HttpErrorResponse)
    ) {

      return (
        'No se pudo generar el reporte.'
      );
    }


    const detalle =
      error.error?.detail;

    if (
      typeof detalle === 'string'
      && detalle.trim()
    ) {

      return detalle;
    }


    switch (
      error.status
    ) {

      case 0:

        return (
          'No se pudo conectar con el servidor.'
        );


      case 400:

        return (
          'Los filtros seleccionados no '
          + 'permiten generar el reporte.'
        );


      case 401:

        return (
          'Tu sesión ha expirado.'
        );


      case 403:

        return (
          'No tienes permisos para '
          + 'generar reportes.'
        );


      case 404:

        return (
          'Uno o más análisis ya no están '
          + 'disponibles.'
        );


      case 500:

        return (
          'Ocurrió un problema al generar '
          + 'el reporte.'
        );


      default:

        return (
          'No se pudo generar el reporte.'
        );
    }
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
