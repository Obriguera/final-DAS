import { Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export interface ISesion {
  cuil: string;
  idCiudadano: string;
  idRefugio: string | null;
  razonSocial: string | null;
  rol: string;
}

// Mantiene el contexto del usuario autenticado durante la navegación.
@Injectable({ providedIn: 'root' })
export class SesionService {
  private readonly KEY = 'sesion';
  private readonly esNavegador = isPlatformBrowser(inject(PLATFORM_ID));

  readonly sesion = signal<ISesion | null>(this.leer());

  iniciar(sesion: ISesion): void {
    if (this.esNavegador) {
      localStorage.setItem(this.KEY, JSON.stringify(sesion));
    }
    this.sesion.set(sesion);
  }

  cerrar(): void {
    if (this.esNavegador) {
      localStorage.removeItem(this.KEY);
    }
    this.sesion.set(null);
  }

  esRefugio(): boolean {
    const sesion = this.sesion();
    return sesion?.rol === 'REFUGIO' && !!sesion.idRefugio;
  }

  private leer(): ISesion | null {
    if (!this.esNavegador) {
      return null;
    }
    try {
      const guardada = localStorage.getItem(this.KEY);
      return guardada ? (JSON.parse(guardada) as ISesion) : null;
    } catch {
      return null;
    }
  }
}
