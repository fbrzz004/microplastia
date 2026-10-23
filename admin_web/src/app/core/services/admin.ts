import { Injectable } from '@angular/core';

import {
  HttpClient,
  HttpHeaders
} from '@angular/common/http';

import { Observable } from 'rxjs';


export interface UsuarioAdmin {
  id_usuario: number;
  nombre: string;
  apellido: string | null;
  correo: string;
  rol: string;
  estado: boolean;

  muestras_realizadas: number;
  ultimo_analisis: string | null;
}


export interface MuestraAdmin {
  id_muestra: number;
  codigo: string;
  usuario: string;
  correo: string;
  fecha: string;

  total_particulas: number;
  confianza_promedio: number;
  estado: string;
}


export interface DashboardAdmin {
  muestras_analizadas: number;
  particulas_detectadas: number;
  usuarios_registrados: number;

  modelo_activo: string;
  modelo_operativo: boolean;

  resolucion_inferencia: number;
  umbral_confianza: number;
  numero_clases: number;

  tiempo_promedio_inferencia_ms: number;
  ultima_inferencia_ms: number | null;

  distribucion: {
    fibra: number;
    fragmento: number;
    gránulo: number;
    película: number;
  };
}


@Injectable({
  providedIn: 'root'
})
export class Admin {

  private readonly apiUrl =
    'http://127.0.0.1:8000/api/v1/admin';

  constructor(
    private http: HttpClient
  ) {}


  private obtenerHeaders(): HttpHeaders {

    const token =
      localStorage.getItem('access_token') ||
      sessionStorage.getItem('access_token');

    return new HttpHeaders({
      Authorization: `Bearer ${token}`
    });
  }


  obtenerDashboard(): Observable<DashboardAdmin> {

    return this.http.get<DashboardAdmin>(
      `${this.apiUrl}/dashboard`,
      {
        headers: this.obtenerHeaders()
      }
    );
  }


  obtenerUsuarios(): Observable<UsuarioAdmin[]> {

    return this.http.get<UsuarioAdmin[]>(
      `${this.apiUrl}/usuarios`,
      {
        headers: this.obtenerHeaders()
      }
    );
  }


  obtenerMuestras(): Observable<MuestraAdmin[]> {

    return this.http.get<MuestraAdmin[]>(
      `${this.apiUrl}/muestras`,
      {
        headers: this.obtenerHeaders()
      }
    );
  }
}