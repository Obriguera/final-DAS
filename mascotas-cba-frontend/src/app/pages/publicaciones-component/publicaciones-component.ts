import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Navbar } from '../navbar/navbar';
import { NuevaPublicacion } from '../nueva-publicacion/nueva-publicacion';
import {
  AccionPublicacion,
  EstadoPublicacion,
  IPublicacion,
  PublicacionesResource,
} from '../../services/publicaciones-resource';
import { SesionService } from '../../services/sesion-service';

// Acciones permitidas según el estado actual (FINALIZADA es terminal)
const ACCIONES_POR_ESTADO: Record<EstadoPublicacion, AccionPublicacion[]> = {
  ACTIVA: ['PAUSAR', 'FINALIZAR'],
  PAUSADA: ['ACTIVAR', 'FINALIZAR'],
  FINALIZADA: [],
};

const FOTO_POR_DEFECTO = 'img/sin-foto.svg';

@Component({
  imports: [Navbar, NuevaPublicacion],
  providers: [PublicacionesResource],
  selector: 'app-publicaciones-component',
  styleUrl: './publicaciones-component.scss',
  templateUrl: './publicaciones-component.html',
})
export class PublicacionesComponent implements OnInit {
  private publicacionesResource = inject(PublicacionesResource);
  private sesion = inject(SesionService);
  private router = inject(Router);

  readonly estados: EstadoPublicacion[] = ['ACTIVA', 'PAUSADA', 'FINALIZADA'];

  publicaciones = signal<IPublicacion[]>([]);
  cargando = signal(true);
  errorMessage = signal<string | null>(null);
  successMessage = signal<string | null>(null);
  mostrarFormulario = signal(false);
  // nroRegMunicipal de la publicación que se está actualizando
  procesando = signal<string | null>(null);

  filtroNombre = signal('');
  filtroEstado = signal<EstadoPublicacion | ''>('');

  publicacionesFiltradas = computed(() => {
    const nombre = this.filtroNombre().trim().toLowerCase();
    const estado = this.filtroEstado();

    return this.publicaciones().filter(
      (p) =>
        (!nombre || p.nombre.toLowerCase().includes(nombre)) &&
        (!estado || p.estadoPublicacion === estado)
    );
  });

  ngOnInit(): void {
    this.cargarPublicaciones();
  }

  cargarPublicaciones(): void {
    this.cargando.set(true);
    this.publicacionesResource.getPublicaciones().subscribe({
      next: (publicaciones) => {
        this.publicaciones.set(publicaciones);
        this.cargando.set(false);
      },
      error: (error) => {
        console.error('Error al obtener las publicaciones:', error);
        this.cargando.set(false);
        this.manejarError(error, 'No se pudieron obtener las publicaciones.');
      },
    });
  }

  accionesDisponibles(publicacion: IPublicacion): AccionPublicacion[] {
    return ACCIONES_POR_ESTADO[publicacion.estadoPublicacion] ?? [];
  }

  cambiarEstado(publicacion: IPublicacion, accion: AccionPublicacion): void {
    if (
      accion === 'FINALIZAR' &&
      !confirm(`¿Finalizar la publicación de ${publicacion.nombre}? Esta acción no se puede deshacer.`)
    ) {
      return;
    }

    this.errorMessage.set(null);
    this.successMessage.set(null);
    this.procesando.set(publicacion.nroRegMunicipal);

    this.publicacionesResource.cambiarEstado(publicacion.nroPublicacion, accion).subscribe({
      next: (resultado) => {
        this.procesando.set(null);
        this.publicaciones.update((lista) =>
          lista.map((p) =>
            p.nroRegMunicipal === publicacion.nroRegMunicipal
              ? { ...p, estadoPublicacion: resultado.estadoPublicacion ?? p.estadoPublicacion }
              : p
          )
        );
        this.successMessage.set(`La publicación de ${publicacion.nombre} ahora está ${this.estadoTexto(resultado.estadoPublicacion!).toLowerCase()}.`);
      },
      error: (error) => {
        console.error('Error al cambiar el estado:', error);
        this.procesando.set(null);
        this.manejarError(error, 'No se pudo cambiar el estado de la publicación.');
        // Si el estado cambió en otro lado, se refresca el listado
        if (error.status === 409 || error.status === 404) {
          this.cargarPublicaciones();
        }
      },
    });
  }

  abrirFormulario(): void {
    this.successMessage.set(null);
    this.mostrarFormulario.set(true);
  }

  onPublicada(): void {
    this.mostrarFormulario.set(false);
    this.successMessage.set('La publicación se registró correctamente.');
    this.cargarPublicaciones();
  }

  onFiltroNombre(event: Event): void {
    this.filtroNombre.set((event.target as HTMLInputElement).value);
  }

  onFiltroEstado(event: Event): void {
    this.filtroEstado.set((event.target as HTMLSelectElement).value as EstadoPublicacion | '');
  }

  estadoTexto(estado: EstadoPublicacion): string {
    return { ACTIVA: 'Activa', PAUSADA: 'Pausada', FINALIZADA: 'Finalizada' }[estado] ?? estado;
  }

  estadoClase(estado: EstadoPublicacion): string {
    return { ACTIVA: 'text-bg-success', PAUSADA: 'text-bg-warning', FINALIZADA: 'text-bg-secondary' }[estado] ?? 'text-bg-light';
  }

  accionTexto(accion: AccionPublicacion): string {
    return { ACTIVAR: 'Activar', PAUSAR: 'Pausar', FINALIZAR: 'Finalizar' }[accion];
  }

  accionClase(accion: AccionPublicacion): string {
    return { ACTIVAR: 'btn-outline-success', PAUSAR: 'btn-outline-warning', FINALIZAR: 'btn-outline-danger' }[accion];
  }

  sexoTexto(sexo: string): string {
    return sexo === 'H' ? 'Hembra' : sexo === 'M' ? 'Macho' : sexo;
  }

  edadTexto(edad: number | null): string {
    if (edad === null || edad === undefined) {
      return 'Edad desconocida';
    }
    if (edad === 0) {
      return 'Menos de 1 año';
    }
    return edad === 1 ? '1 año' : `${edad} años`;
  }

  // Las fotos se sirven desde public/img; si es una URL completa se usa tal cual
  fotoUrl(foto: string): string {
    if (!foto) {
      return FOTO_POR_DEFECTO;
    }
    return /^(https?:|data:)/.test(foto) ? foto : `img/${foto}`;
  }

  onFotoError(event: Event): void {
    const img = event.target as HTMLImageElement;
    if (!img.src.endsWith(FOTO_POR_DEFECTO)) {
      img.src = FOTO_POR_DEFECTO;
    }
  }

  private manejarError(error: { status?: number; error?: { mensaje?: string } }, porDefecto: string): void {
    // El backend responde 403 cuando el usuario ya no es responsable del refugio
    if (error.status === 403) {
      this.sesion.logout();
      this.router.navigate(['/']);
      return;
    }
    this.errorMessage.set(error.error?.mensaje ?? porDefecto);
  }
}
