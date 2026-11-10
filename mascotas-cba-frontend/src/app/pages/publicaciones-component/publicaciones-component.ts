import { Component, OnInit, computed, inject, signal } from "@angular/core";
import { Navbar } from "../navbar/navbar";
import { NuevaPublicacion } from "../nueva-publicacion/nueva-publicacion";
import {
  AccionPublicacion,
  EstadoPublicacion,
  INuevaPublicacion,
  IPublicacion,
  ISexo,
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

  // Opciones para el formulario modal
  especies = signal<string[]>([]);
  razas = signal<string[]>([]);
  sexos = signal<ISexo[]>([]);
  guardandoPublicacion = signal(false);
  errorModal = signal<string | null>(null);

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
    this.cargarOpcionesFormulario();
  }

  cargarOpcionesFormulario(): void {
    this.publicacionesResource.getEspecies().subscribe({
      next: (v) => this.especies.set(v),
      error: (e) => console.error("Error al cargar especies:", e),
    });
    this.publicacionesResource.getRazas().subscribe({
      next: (v) => this.razas.set(v),
      error: (e) => console.error("Error al cargar razas:", e),
    });
    this.publicacionesResource.getSexos().subscribe({
      next: (v) => this.sexos.set(v),
      error: (e) => console.error("Error al cargar sexos:", e),
    });
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
          if (error.status === 409 || error.status === 404) {
            this.cargarPublicaciones();
          }
        },
      });
  }

  abrirFormulario(): void {
    this.errorModal.set(null);
    this.successMessage.set(null);
    this.mostrarFormulario.set(true);
  }

  onCrearPublicacion(evento: {
    datos: INuevaPublicacion;
    fotoBase64: string | null;
  }): void {
    this.guardandoPublicacion.set(true);
    this.errorModal.set(null);

    this.publicacionesResource.crearPublicacion(evento.datos).subscribe({
      next: (resultado) => {
        if (evento.fotoBase64 && typeof localStorage !== "undefined") {
          try {
            const nombreNormalizado = evento.datos.nombre.trim().toLowerCase();
            localStorage.setItem(`foto_${nombreNormalizado}`, evento.fotoBase64);

            const nroReg = resultado?.["nroRegMunicipal"];
            const nroPub = resultado?.["nroPublicacion"];
            if (nroReg) {
              localStorage.setItem(`foto_${nroReg}`, evento.fotoBase64);
            }
            if (nroPub) {
              localStorage.setItem(`foto_${nroPub}`, evento.fotoBase64);
            }
          } catch (e) {
            console.warn("No se pudo guardar la foto en localStorage:", e);
          }
        }

        this.guardandoPublicacion.set(false);
        this.mostrarFormulario.set(false);
        this.successMessage.set("La publicación se registró correctamente.");
        this.cargarPublicaciones();
      },
      error: (error) => {
        console.error("Error al crear la publicación:", error);
        this.guardandoPublicacion.set(false);
        if (error.status === 401) {
          return;
        }
        this.errorModal.set(
          error.status === 403
            ? "No tiene permisos para realizar esta operación."
            : (error.error?.mensaje ??
                "No se pudo registrar la publicación. Intente nuevamente."),
        );
      },
    });
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
