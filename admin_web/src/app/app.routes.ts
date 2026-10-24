import { Routes } from '@angular/router';

import { AdminLayout } from './shared/components/admin-layout/admin-layout';

import { Dashboard } from './features/dashboard/pages/dashboard/dashboard';
import { Muestras } from './features/muestras/pages/muestras/muestras';
import { Usuarios } from './features/usuarios/pages/usuarios/usuarios';
import { Login } from './features/auth/pages/login/login';

import { authGuard } from './core/guards/auth-guard';

export const routes: Routes = [

  // ==========================================
  // LOGIN
  // ==========================================

  {
    path: 'login',
    component: Login
  },


  // ==========================================
  // PANEL ADMINISTRATIVO
  // ==========================================

  {
    path: '',
    component: AdminLayout,
    canActivate: [authGuard],

    children: [

      {
        path: 'dashboard',
        component: Dashboard
      },

      {
        path: 'muestras',
        component: Muestras
      },

      {
        path: 'usuarios',
        component: Usuarios
      },

      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full'
      }

    ]
  },


  // ==========================================
  // RUTAS NO EXISTENTES
  // ==========================================

  {
    path: '**',
    redirectTo: 'login'
  }

];