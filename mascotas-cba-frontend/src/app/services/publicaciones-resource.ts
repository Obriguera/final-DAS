import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../environments/environments';

export type EstadoPublicacion = 'ACTIVA' | 'PAUSADA' | 'FINALIZADA';
export type AccionPublicacion = 'ACTIVAR' | 'PAUSAR' | 'FINALIZAR';

export interface IPublicacion {
  nroPublicacion: string;
  nroRegMunicipal: string;
  nombre: string;
  especie: string;
  sexo: 'H' | 'M';
  edad: number | null;
  raza?: string | null;
  caracteristicasMascota: string;
  condicionAdopcion: string;
  foto: string;
  estadoPublicacion: EstadoPublicacion;
  fechaPublicacion: string;
}

export interface INuevaPublicacion {
  nombre: string;
  especie: string;
  sexo: string;
  edadAproximada: string;
  raza: string;
  caracteristicasMascota: string;
  condicionAdopcion: string;
  foto: string;
}

export interface IResultadoPublicacion {
  resultado: 'OK' | 'ERROR';
  codigo?: string;
  mensaje?: string;
  nroPublicacion?: string;
  nroRegMunicipal?: string;
  estadoPublicacion?: EstadoPublicacion;
}

@Injectable()
export class PublicacionesResource {
  private http = inject(HttpClient);
  private readonly apiUrl = `${environment.apiUrl}/publicaciones`;

  getPublicaciones(): Observable<IPublicacion[]> {
    return this.http.get<IPublicacion[]>(this.apiUrl);
  }

  crearPublicacion(datos: INuevaPublicacion): Observable<IResultadoPublicacion> {
    return this.http.post<IResultadoPublicacion>(this.apiUrl, datos);
  }

  cambiarEstado(nroPublicacion: string, accion: AccionPublicacion): Observable<IResultadoPublicacion> {
    return this.http.patch<IResultadoPublicacion>(`${this.apiUrl}/estado`, { nroPublicacion, accion });
  }
}
