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

  constructor(
    private router: Router,
    private auth: Auth
  ) {}


  cerrarSesion(): void {

    this.auth.logout();


    this.router.navigate(
      ['/login']
    );
  }
}