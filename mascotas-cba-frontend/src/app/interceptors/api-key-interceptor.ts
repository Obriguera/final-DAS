import { HttpInterceptorFn } from '@angular/common/http';
import { environment } from '../environments/environments';

export const apiKeyInterceptor: HttpInterceptorFn = (req, next) => {
  const token = typeof localStorage !== 'undefined' ? localStorage.getItem('token') : null;

  const authReq = req.clone({
    setHeaders: {
      'X-API-Key': environment.apiKey,
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    }
  });

  return next(authReq);
};
