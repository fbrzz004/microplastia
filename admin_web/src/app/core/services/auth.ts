import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

import { Observable } from 'rxjs';

import {
  API_BASE_URL
} from '../config/api-config';


export interface UsuarioLogin {
  id_usuario: number;
  nombre: string;
  apellido: string | null;
  correo: string;
  rol: string;
  estado: boolean;
}


export interface LoginResponse {
  access_token: string;
  token_type: string;
  usuario: UsuarioLogin;
}


@Injectable({
  providedIn: 'root'
})
export class Auth {

  private readonly apiUrl =
    `${API_BASE_URL}/auth`;


  constructor(
    private http: HttpClient
  ) {}


  // ========================================================
  // LOGIN
  // ========================================================

  login(
    correo: string,
    password: string
  ): Observable<LoginResponse> {

    return this.http.post<LoginResponse>(
      `${this.apiUrl}/login`,
      {
        correo: correo.trim().toLowerCase(),
        password
      }
    );
  }


  // ========================================================
  // GUARDAR SESIÓN
  // ========================================================

  guardarSesion(
    respuesta: LoginResponse,
    mantenerSesion: boolean
  ): void {

    this.limpiarSesion();

    const storage =
      mantenerSesion
        ? localStorage
        : sessionStorage;


    storage.setItem(
      'access_token',
      respuesta.access_token
    );


    storage.setItem(
      'usuario',
      JSON.stringify(
        respuesta.usuario
      )
    );
  }


  // ========================================================
  // TOKEN
  // ========================================================

  obtenerToken(): string | null {

    return (
      localStorage.getItem(
        'access_token'
      ) ||
      sessionStorage.getItem(
        'access_token'
      )
    );
  }


  // ========================================================
  // USUARIO
  // ========================================================

  obtenerUsuario(): UsuarioLogin | null {

    const stored =
      localStorage.getItem('usuario') ||
      sessionStorage.getItem('usuario');


    if (!stored) {
      return null;
    }


    try {

      const usuario =
        JSON.parse(stored);

      if (
        typeof usuario !== 'object' ||
        usuario === null
      ) {
        return null;
      }


      return usuario as UsuarioLogin;

    } catch {

      return null;
    }
  }


  // ========================================================
  // SESIÓN
  // ========================================================

  sesionValida(): boolean {

    const token =
      this.obtenerToken();

    const usuario =
      this.obtenerUsuario();


    if (
      !token ||
      !usuario
    ) {

      this.limpiarSesion();

      return false;
    }


    if (
      usuario.rol !== 'administrador' ||
      usuario.estado !== true
    ) {

      this.limpiarSesion();

      return false;
    }


    if (
      this.tokenExpirado(token)
    ) {

      this.limpiarSesion();

      return false;
    }


    return true;
  }


  esAdministrador(): boolean {

    const usuario =
      this.obtenerUsuario();

    return (
      usuario?.rol === 'administrador' &&
      usuario?.estado === true
    );
  }


  // ========================================================
  // LOGOUT
  // ========================================================

  logout(): void {

    this.limpiarSesion();
  }


  limpiarSesion(): void {

    localStorage.removeItem(
      'access_token'
    );

    localStorage.removeItem(
      'usuario'
    );


    sessionStorage.removeItem(
      'access_token'
    );

    sessionStorage.removeItem(
      'usuario'
    );
  }


  // ========================================================
  // EXPIRACIÓN JWT
  // ========================================================

  private tokenExpirado(
    token: string
  ): boolean {

    try {

      const parts =
        token.split('.');


      if (parts.length !== 3) {
        return true;
      }


      const payload =
        parts[1]
          .replace(/-/g, '+')
          .replace(/_/g, '/');


      const decoded =
        JSON.parse(
          decodeURIComponent(
            Array.prototype.map
              .call(
                atob(payload),
                (char: string) => {
                  return (
                    '%' +
                    (
                      '00' +
                      char
                        .charCodeAt(0)
                        .toString(16)
                    ).slice(-2)
                  );
                }
              )
              .join('')
          )
        );


      if (
        typeof decoded.exp !== 'number'
      ) {
        return true;
      }


      const now =
        Math.floor(
          Date.now() / 1000
        );


      return decoded.exp <= now;

    } catch {

      return true;
    }
  }
}