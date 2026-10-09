import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { environment } from '../environments/environments';
import { SesionService } from '../services/sesion-service';

export const apiKeyInterceptor: HttpInterceptorFn = (req, next) => {
  const sesion = inject(SesionService).sesion();

  // El backend identifica al usuario y a su refugio con los ids devueltos por el login.
  const authReq = req.clone({
    setHeaders: {
      'X-API-Key': environment.apiKey,
      ...(sesion ? { 'X-Id-Ciudadano': sesion.idCiudadano } : {}),
      ...(sesion?.idRefugio ? { 'X-Id-Refugio': sesion.idRefugio } : {})
    }
  });

  return next(authReq);
};
