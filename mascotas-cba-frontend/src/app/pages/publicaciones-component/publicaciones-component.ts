import { Component, OnInit, computed, inject, signal } from "@angular/core";
import { Navbar } from "../navbar/navbar";
import { NuevaPublicacion } from "../nueva-publicacion/nueva-publicacion";
import {
  AccionPublicacion,
  EstadoPublicacion,
  IPublicacion,
  PublicacionesResource,
} from "../../services/publicaciones-resource";

const ACCIONES_POR_ESTADO: Record<EstadoPublicacion, AccionPublicacion[]> = {
  ACTIVA: ["PAUSAR", "FINALIZAR"],
  PAUSADA: ["ACTIVAR", "FINALIZAR"],
  FINALIZADA: [],
};

const FOTO_POR_DEFECTO = "img/sin-foto.svg";

@Component({
  imports: [Navbar, NuevaPublicacion],
  providers: [PublicacionesResource],
  selector: "app-publicaciones-component",
  styleUrl: "./publicaciones-component.scss",
  templateUrl: "./publicaciones-component.html",
})
export class PublicacionesComponent implements OnInit {
  private publicacionesResource = inject(PublicacionesResource);

  readonly estados: EstadoPublicacion[] = ["ACTIVA", "PAUSADA", "FINALIZADA"];

  publicaciones = signal<IPublicacion[]>([]);
  cargando = signal(true);
  errorMessage = signal<string | null>(null);
  successMessage = signal<string | null>(null);
  mostrarFormulario = signal(false);
  procesando = signal<number | null>(null);

  filtroNombre = signal("");
  filtroEstado = signal<EstadoPublicacion | "">("");

  publicacionesFiltradas = computed(() => {
    const nombre = this.filtroNombre().trim().toLowerCase();
    const estado = this.filtroEstado();

    return this.publicaciones().filter(
      (p) =>
        (!nombre || p.nombre.toLowerCase().includes(nombre)) &&
        (!estado || p.estadoPublicacion === estado),
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
        console.error("Error al obtener las publicaciones:", error);
        this.cargando.set(false);
        this.manejarError(error, "No se pudieron obtener las publicaciones.");
      },
    });
  }

  accionesDisponibles(publicacion: IPublicacion): AccionPublicacion[] {
    return ACCIONES_POR_ESTADO[publicacion.estadoPublicacion] ?? [];
  }

  cambiarEstado(publicacion: IPublicacion, accion: AccionPublicacion): void {
    if (
      accion === "FINALIZAR" &&
      !confirm(
        `¿Finalizar la publicación de ${publicacion.nombre}? Esta acción no se puede deshacer.`,
      )
    ) {
      return;
    }

    this.errorMessage.set(null);
    this.successMessage.set(null);
    this.procesando.set(publicacion.nroPublicacion);

    this.publicacionesResource
      .cambiarEstado(publicacion.nroPublicacion, accion)
      .subscribe({
        next: (resultado) => {
          this.procesando.set(null);
          this.publicaciones.update((lista) =>
            lista.map((p) =>
              p.nroPublicacion === publicacion.nroPublicacion
                ? { ...p, estadoPublicacion: resultado.estadoPublicacion }
                : p,
            ),
          );
          this.successMessage.set(
            `La publicación de ${publicacion.nombre} ahora está ${this.estadoTexto(resultado.estadoPublicacion).toLowerCase()}.`,
          );
        },
        error: (error) => {
          console.error("Error al cambiar el estado:", error);
          this.procesando.set(null);
          this.manejarError(
            error,
            "No se pudo cambiar el estado de la publicación.",
          );
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
    this.successMessage.set("La publicación se registró correctamente.");
    this.cargarPublicaciones();
  }

  onFiltroNombre(event: Event): void {
    this.filtroNombre.set((event.target as HTMLInputElement).value);
  }

  onFiltroEstado(event: Event): void {
    this.filtroEstado.set(
      (event.target as HTMLSelectElement).value as EstadoPublicacion | "",
    );
  }

  estadoTexto(estado: EstadoPublicacion): string {
    return (
      { ACTIVA: "Activa", PAUSADA: "Pausada", FINALIZADA: "Finalizada" }[
        estado
      ] ?? estado
    );
  }

  estadoClase(estado: EstadoPublicacion): string {
    return (
      {
        ACTIVA: "text-bg-success",
        PAUSADA: "text-bg-warning",
        FINALIZADA: "text-bg-secondary",
      }[estado] ?? "text-bg-light"
    );
  }

  accionTexto(accion: AccionPublicacion): string {
    return { ACTIVAR: "Activar", PAUSAR: "Pausar", FINALIZAR: "Finalizar" }[
      accion
    ];
  }

  accionClase(accion: AccionPublicacion): string {
    return {
      ACTIVAR: "btn-outline-success",
      PAUSAR: "btn-outline-warning",
      FINALIZAR: "btn-outline-danger",
    }[accion];
  }

  sexoTexto(sexo: string): string {
    return sexo === "H" ? "Hembra" : sexo === "M" ? "Macho" : sexo;
  }

  edadTexto(edad: number | null): string {
    if (edad === null || edad === undefined) {
      return "Edad desconocida";
    }
    if (edad === 0) {
      return "Menos de 1 año";
    }
    return edad === 1 ? "1 año" : `${edad} años`;
  }

  fotoUrl(item: IPublicacion | string): string {
    if (!item) {
      return FOTO_POR_DEFECTO;
    }

    if (typeof item !== "string" && typeof localStorage !== "undefined") {
      const fotoLocal =
        (item.nroRegMunicipal
          ? localStorage.getItem(`foto_${item.nroRegMunicipal}`)
          : null) ??
        (item.nroPublicacion
          ? localStorage.getItem(`foto_${item.nroPublicacion}`)
          : null) ??
        (item.nombre
          ? localStorage.getItem(`foto_${item.nombre.trim().toLowerCase()}`)
          : null);

      if (fotoLocal) {
        return fotoLocal;
      }
    }

    const foto = typeof item === "string" ? item : item.foto;
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

  private manejarError(
    error: { status?: number; error?: { mensaje?: string } },
    porDefecto: string,
  ): void {
    // 401 lo resuelve el interceptor (vuelve al login)
    if (error.status === 401) {
      return;
    }
    if (error.status === 403) {
      this.errorMessage.set("No tiene permisos para realizar esta operación.");
      return;
    }
    this.errorMessage.set(error.error?.mensaje ?? porDefecto);
  }
}
