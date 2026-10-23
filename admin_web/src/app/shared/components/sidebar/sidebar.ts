import { Component } from '@angular/core';

import {
  Router,
  RouterLink,
  RouterLinkActive
} from '@angular/router';

@Component({
  selector: 'app-sidebar',
  standalone: true,

  imports: [
    RouterLink,
    RouterLinkActive
  ],

  templateUrl: './sidebar.html',
  styleUrl: './sidebar.css'
})
export class Sidebar {

  constructor(
    private router: Router
  ) {}

  cerrarSesion(): void {

    localStorage.removeItem('access_token');
    localStorage.removeItem('usuario');

    sessionStorage.removeItem('access_token');
    sessionStorage.removeItem('usuario');

    this.router.navigate(['/login']);
  }
}