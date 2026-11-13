import {
  Component
} from '@angular/core';

import {
  Router,
  RouterLink,
  RouterLinkActive
} from '@angular/router';

import {
  Auth
} from '../../../core/services/auth';


@Component({
  selector: 'app-sidebar',

  standalone: true,

  imports: [
    RouterLink,
    RouterLinkActive
  ],

  templateUrl:
    './sidebar.html',

  styleUrl:
    './sidebar.css'
})
export class Sidebar {

  mostrarConfirmacionSalida = false;


  constructor(
    private router: Router,
    private auth: Auth
  ) {}


  solicitarCerrarSesion(): void {

    this.mostrarConfirmacionSalida = true;
  }


  cancelarCerrarSesion(): void {

    this.mostrarConfirmacionSalida = false;
  }


  confirmarCerrarSesion(): void {

    this.mostrarConfirmacionSalida = false;

    this.auth.logout();

    this.router.navigate(
      ['/login']
    );
  }
}
