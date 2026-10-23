import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface UsuarioLogin {
  id_usuario: number;
  nombre: string;
  apellido: string;
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
  private readonly apiUrl = 'http://127.0.0.1:8000/api/v1/auth';

  constructor(private http: HttpClient) {}

  login(correo: string, password: string): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.apiUrl}/login`, {
      correo,
      password
    });
  }
}