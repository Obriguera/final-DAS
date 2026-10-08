import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../environments/environments';

export interface ILoginResponse {
  idCiudadano: string;
  idRefugio: string | null;
  idVeterinaria: string | null;
  razonSocial: string | null;
  rol: string;
  token: string;
}

@Injectable()
export class LoginResource {
  private http = inject(HttpClient);
  private readonly apiUrl = `${environment.apiUrl}/login`;

  login(cuil: string, clave: string): Observable<ILoginResponse> {
    return this.http.post<ILoginResponse>(this.apiUrl, { cuil, clave });
  }
}
