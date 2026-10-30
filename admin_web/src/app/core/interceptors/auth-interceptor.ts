import { inject } from '@angular/core';

import {
  HttpErrorResponse,
  HttpInterceptorFn
} from '@angular/common/http';

import {
  Router
} from '@angular/router';

import {
  catchError,
  throwError,
  timeout
} from 'rxjs';

import {
  API_CONFIG
} from '../config/api-config';

import {
  Auth
} from '../services/auth';


export const authInterceptor:
  HttpInterceptorFn = (
    request,
    next
  ) => {

    const auth =
      inject(Auth);

    const router =
      inject(Router);


    // ======================================================
    // TOKEN
    // ======================================================

    const token =
      auth.obtenerToken();


    const esRequestApi =
      request.url.startsWith(
        API_CONFIG.baseUrl
      );


    const esLogin =
      request.url.includes(
        '/auth/login'
      );


    let secureRequest =
      request;


    if (
      esRequestApi &&
      !esLogin &&
      token
    ) {

      secureRequest =
        request.clone({
          setHeaders: {
            Authorization:
              `Bearer ${token}`
          }
        });
    }


    // ======================================================
    // REQUEST
    // ======================================================

    return next(
      secureRequest
    ).pipe(

      timeout(
        API_CONFIG.timeoutMs
      ),

      catchError(
        (
          error: unknown
        ) => {

          if (
            error instanceof
            HttpErrorResponse
          ) {

            // ==============================================
            // 401 - SESIÓN INVÁLIDA / EXPIRADA
            // ==============================================

            if (
              error.status === 401 &&
              !esLogin
            ) {

              auth.limpiarSesion();

              router.navigate(
                ['/login']
              );
            }


            // ==============================================
            // 403
            // ==============================================

            if (
              error.status === 403 &&
              !esLogin
            ) {

              const usuario =
                auth.obtenerUsuario();


              if (
                !usuario ||
                usuario.rol !==
                  'administrador'
              ) {

                auth.limpiarSesion();

                router.navigate(
                  ['/login']
                );
              }
            }
          }


          return throwError(
            () => error
          );
        }
      )
    );
  };