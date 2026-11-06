import { HttpErrorResponse, HttpInterceptorFn } from "@angular/common/http";
import { inject } from "@angular/core";
import { Router } from "@angular/router";
import { catchError, throwError } from "rxjs";
import { environment } from "../environments/environments";
import { SesionService } from "../services/sesion-service";

export const apiKeyInterceptor: HttpInterceptorFn = (req, next) => {
  const sesion = inject(SesionService);
  const router = inject(Router);

  const authReq = req.clone({
    setHeaders: { "X-API-Key": environment.apiKey },
    withCredentials: true,
  });

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401 && !req.url.endsWith("/login")) {
        sesion.logout();
        router.navigate(["/"]);
      }
      return throwError(() => error);
    }),
  );
};
