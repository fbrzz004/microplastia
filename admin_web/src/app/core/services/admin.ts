import {
  Injectable
} from '@angular/core';

import {
  HttpClient
} from '@angular/common/http';

import {
  Observable
} from 'rxjs';

import {
  API_BASE_URL
} from '../config/api-config';


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

  modelo_nombre: string | null;

  modelo_version: string | null;

  modelo_origen: string | null;
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

  analisis_con_modelo: number;

  uso_downloaded: number;

  uso_fallback: number;

  porcentaje_downloaded: number;

  porcentaje_fallback: number;

  alerta_fallback: boolean;
}


export interface AdminNotificationItem {

  id: number;

  type: string;

  title: string;

  message: string;

  result_id: number | null;

  is_read: boolean;

  created_at: string | null;
}


export interface AdminNotificationListData {

  items: AdminNotificationItem[];

  total: number;

  unread_count: number;

  limit: number;

  offset: number;
}


export interface AdminNotificationListResponse {

  success: boolean;

  data: AdminNotificationListData;
}


export interface AdminNotificationReadResponse {

  success: boolean;

  data: AdminNotificationItem;
}


@Injectable({
  providedIn: 'root'
})
export class Admin {

  private readonly apiUrl =
    `${API_BASE_URL}/admin`;


  constructor(
    private http: HttpClient
  ) {}


  obtenerDashboard():
    Observable<DashboardAdmin> {

    return this.http.get<DashboardAdmin>(
      `${this.apiUrl}/dashboard`
    );
  }


  obtenerUsuarios():
    Observable<UsuarioAdmin[]> {

    return this.http.get<UsuarioAdmin[]>(
      `${this.apiUrl}/usuarios`
    );
  }


  obtenerMuestras():
    Observable<MuestraAdmin[]> {

    return this.http.get<MuestraAdmin[]>(
      `${this.apiUrl}/muestras`
    );
  }


  obtenerNotificaciones():
    Observable<AdminNotificationListResponse> {

    return this.http.get<AdminNotificationListResponse>(
      `${API_BASE_URL}/notifications`,
      {
        params: {
          limit: 20,
          offset: 0
        }
      }
    );
  }


  marcarNotificacionLeida(
    notificationId: number
  ): Observable<AdminNotificationReadResponse> {

    return this.http.post<AdminNotificationReadResponse>(
      `${API_BASE_URL}/notifications/${notificationId}/read`,
      {}
    );
  }


  marcarTodasNotificacionesLeidas():
    Observable<void> {

    return this.http.post<void>(
      `${API_BASE_URL}/notifications/read-all`,
      {}
    );
  }
}