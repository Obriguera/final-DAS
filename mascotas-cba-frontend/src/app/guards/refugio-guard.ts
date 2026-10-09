import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { SesionService } from '../services/sesion-service';

// Solo deja pasar a usuarios autenticados con perfil Refugio.
export const refugioGuard: CanActivateFn = () => {
  return inject(SesionService).esRefugio() ? true : inject(Router).createUrlTree(['/']);
};
