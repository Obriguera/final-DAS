import { Injectable, inject } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";
import { environment } from "../environments/environments";

export type EstadoPublicacion = "ACTIVA" | "PAUSADA" | "FINALIZADA";
export type AccionPublicacion = "ACTIVAR" | "PAUSAR" | "FINALIZAR";

export interface IPublicacion {
  nroPublicacion: number;
  nroRegMunicipal: string;
  nombre: string;
  especie: string;
  raza: string | null;
  sexo: string;
  anioNacimiento: number | null;
  edad: number | null;
  caracteristicasMascota: string;
  condicionAdopcion: string;
  foto: string;
  estadoPublicacion: EstadoPublicacion;
  fechaPublicacion: string;
}

export interface ISexo {
  codigo: string;
  nombre: string;
}

export interface INuevaPublicacion {
  nombre: string;
  especie: string;
  sexo: string;
  edadAproximada?: string;
  anioNacimiento?: number | null;
  raza?: string;
  caracteristicasMascota: string;
  condicionAdopcion: string;
  foto: string;
}

export interface ICambioEstado {
  nroPublicacion: number;
  accion: AccionPublicacion;
}

export type IResultadoCrear = Record<string, unknown>;

export interface IResultadoEstado {
  estadoPublicacion: EstadoPublicacion;
}

@Injectable({
  providedIn: "root",
})
export class PublicacionesResource {
  private http = inject(HttpClient);
  private readonly apiUrl = `${environment.apiUrl}/publicaciones`;

  getPublicaciones(): Observable<IPublicacion[]> {
    return this.http.get<IPublicacion[]>(this.apiUrl);
  }

  getEspecies(): Observable<string[]> {
    return this.http.get<string[]>(`${this.apiUrl}/especies`);
  }

  getRazas(): Observable<string[]> {
    return this.http.get<string[]>(`${this.apiUrl}/razas`);
  }

  getSexos(): Observable<ISexo[]> {
    return this.http.get<ISexo[]>(`${this.apiUrl}/sexos`);
  }

  crearPublicacion(datos: INuevaPublicacion): Observable<IResultadoCrear> {
    return this.http.post<IResultadoCrear>(this.apiUrl, datos);
  }

  cambiarEstado(
    nroPublicacion: number,
    accion: AccionPublicacion,
  ): Observable<IResultadoEstado> {
    const cambio: ICambioEstado = { nroPublicacion, accion };
    return this.http.patch<IResultadoEstado>(`${this.apiUrl}/estado`, cambio);
  }
}
