import { Component, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { SesionService } from '../services/sesion-service';

@Component({
  imports: [RouterLink],
  selector: 'app-navbar',
  styleUrl: './navbar.scss',
  templateUrl: './navbar.html',
})
export class Navbar {
  private router = inject(Router);
  private sesionService = inject(SesionService);
  protected sesion = this.sesionService.sesion;

  cerrarSesion(): void {
    this.sesionService.cerrar();
    this.router.navigate(['/']);
  }
}
