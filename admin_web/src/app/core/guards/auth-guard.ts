import {
  inject
} from '@angular/core';

import {
  CanActivateChildFn,
  CanActivateFn,
  Router
} from '@angular/router';

import {
  Auth
} from '../services/auth';


function verificarAcceso() {

  const auth =
    inject(Auth);

  const router =
    inject(Router);


  if (
    !auth.sesionValida()
  ) {

    return router.createUrlTree(
      ['/login']
    );
  }


  return true;
}


export const authGuard:
  CanActivateFn = () => {

    return verificarAcceso();
  };


export const authChildGuard:
  CanActivateChildFn = () => {

    return verificarAcceso();
  };


export const guestGuard:
  CanActivateFn = () => {

    const auth =
      inject(Auth);

    const router =
      inject(Router);


    if (
      auth.sesionValida()
    ) {

      return router.createUrlTree(
        ['/dashboard']
      );
    }


    return true;
  };