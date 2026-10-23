import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

export const authGuard: CanActivateFn = () => {
  const router = inject(Router);

  const token =
    localStorage.getItem('access_token') ||
    sessionStorage.getItem('access_token');

  const usuarioGuardado =
    localStorage.getItem('usuario') ||
    sessionStorage.getItem('usuario');

  if (!token || !usuarioGuardado) {
    return router.createUrlTree(['/login']);
  }

  try {
    const usuario = JSON.parse(usuarioGuardado);

    if (usuario.rol !== 'administrador') {
      limpiarSesion();

      return router.createUrlTree(['/login']);
    }

    return true;

  } catch {
    limpiarSesion();

    return router.createUrlTree(['/login']);
  }
};

function limpiarSesion(): void {
  localStorage.removeItem('access_token');
  localStorage.removeItem('usuario');

  sessionStorage.removeItem('access_token');
  sessionStorage.removeItem('usuario');
}