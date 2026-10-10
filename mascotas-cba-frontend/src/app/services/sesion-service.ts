import { computed, inject, Injectable, PLATFORM_ID, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export interface UsuarioSesion {
  cuil?: string | null;
  idCiudadano?: string | null;
  idRefugio?: string | null;
  idVeterinaria?: string | null;
  razonSocial?: string | null;
  rol: string;
}

@Injectable()
export class SesionService {
  private readonly platformId = inject(PLATFORM_ID);
  private readonly STORAGE_KEY = 'sesion';

  private get storage(): Storage | null {
    return isPlatformBrowser(this.platformId) ? sessionStorage : null;
  }

  readonly sesion = signal<UsuarioSesion | null>(this.leer());
  readonly autenticado = computed(() => !!this.sesion()?.rol);

  setSesion(sesion: UsuarioSesion): void {
    this.storage?.setItem(this.STORAGE_KEY, JSON.stringify(sesion));
    this.sesion.set(sesion);
  }

  logout(): void {
    this.storage?.removeItem(this.STORAGE_KEY);
    this.sesion.set(null);
  }

  isAuthenticated(): boolean {
    return this.autenticado();
  }

  hasRole(rolesPermitidos: string[]): boolean {
    const rol = this.sesion()?.rol;
    return !!rol && rolesPermitidos.includes(rol);
  }

  esRefugio(): boolean {
    const sesion = this.sesion();
    return sesion?.rol === 'REFUGIO' && !!sesion.idRefugio;
  }

  private leer(): UsuarioSesion | null {
    const data = this.storage?.getItem(this.STORAGE_KEY);
    if (!data) return null;
    try {
      const parsed = JSON.parse(data);
      return typeof parsed?.rol === 'string' ? (parsed as UsuarioSesion) : null;
    } catch {
      return null;
    }
  }
}