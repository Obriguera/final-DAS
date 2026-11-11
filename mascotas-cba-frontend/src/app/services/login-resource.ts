import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../environments/environments';

export interface ILoginResponse {
  apellido: string | null;
  nombre: string | null;
  razonSocial: string | null;
  rol: string;
}

@Injectable()
export class LoginResource {
  private http = inject(HttpClient);
  private readonly apiUrl = `${environment.apiUrl}/auth/login`;

  login(cuil: string, clave: string): Observable<ILoginResponse> {
    return this.http.post<ILoginResponse>(this.apiUrl, { cuil, clave });
  }
}
