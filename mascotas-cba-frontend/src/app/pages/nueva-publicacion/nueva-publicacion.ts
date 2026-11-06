import {
  Component,
  OnDestroy,
  OnInit,
  inject,
  output,
  signal,
} from "@angular/core";
import {
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from "@angular/forms";
import {
  INuevaPublicacion,
  ISexo,
  PublicacionesResource,
} from "../../services/publicaciones-resource";

@Component({
  imports: [ReactiveFormsModule],
  selector: "app-nueva-publicacion",
  styleUrl: "./nueva-publicacion.scss",
  templateUrl: "./nueva-publicacion.html",
})
export class NuevaPublicacion implements OnInit, OnDestroy {
  private publicacionesResource = inject(PublicacionesResource);

  readonly publicada = output<void>();
  readonly cancelada = output<void>();

  especies = signal<string[]>([]);
  razas = signal<string[]>([]);
  sexos = signal<ISexo[]>([]);

  errorMessage = signal<string | null>(null);
  enviando = signal(false);
  vistaPrevia = signal<string | null>(null);
  private fotoBase64: string | null = null;

  publicacionForm = new FormGroup({
    nombre: new FormControl<string>("", {
      nonNullable: true,
      validators: [Validators.required, Validators.maxLength(100)],
    }),
    especie: new FormControl<string>("", {
      nonNullable: true,
      validators: [Validators.required],
    }),
    sexo: new FormControl<string>("", {
      nonNullable: true,
      validators: [Validators.required],
    }),
    edadAproximada: new FormControl<string>("", {
      nonNullable: true,
      validators: [Validators.pattern(/^\s*\d+(\s+\D.*)?$/)],
    }),
    raza: new FormControl<string>("", {
      nonNullable: true,
      validators: [Validators.maxLength(200)],
    }),
    caracteristicasMascota: new FormControl<string>("", {
      nonNullable: true,
      validators: [Validators.required, Validators.maxLength(500)],
    }),
    condicionAdopcion: new FormControl<string>("", {
      nonNullable: true,
      validators: [Validators.required, Validators.maxLength(300)],
    }),
    foto: new FormControl<string>("", {
      nonNullable: true,
      validators: [Validators.required, Validators.maxLength(300)],
    }),
  });

  ngOnInit(): void {
    const falla = (error: unknown) => {
      console.error("Error al cargar los datos del formulario:", error);
      this.errorMessage.set(
        "No se pudieron cargar las opciones del formulario.",
      );
    };
    this.publicacionesResource
      .getEspecies()
      .subscribe({ next: (v) => this.especies.set(v), error: falla });
    this.publicacionesResource
      .getRazas()
      .subscribe({ next: (v) => this.razas.set(v), error: falla });
    this.publicacionesResource
      .getSexos()
      .subscribe({ next: (v) => this.sexos.set(v), error: falla });
  }

  onFotoSeleccionada(event: Event): void {
    const input = event.target as HTMLInputElement;
    const archivo = input.files?.[0];
    this.liberarVistaPrevia();
    this.fotoBase64 = null;

    if (!archivo) {
      this.publicacionForm.controls.foto.setValue("");
    } else {
      this.publicacionForm.controls.foto.setValue(archivo.name);
      this.procesarImagen(archivo);
    }
    this.publicacionForm.controls.foto.markAsTouched();
  }

  private procesarImagen(archivo: File): void {
    const lector = new FileReader();
    lector.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const MAX_DIM = 600;
        let width = img.width;
        let height = img.height;

        if (width > height && width > MAX_DIM) {
          height = Math.round((height * MAX_DIM) / width);
          width = MAX_DIM;
        } else if (height > MAX_DIM) {
          width = Math.round((width * MAX_DIM) / height);
          height = MAX_DIM;
        }

        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext("2d");
        if (ctx) {
          ctx.drawImage(img, 0, 0, width, height);
          const base64 = canvas.toDataURL("image/jpeg", 0.85);
          this.fotoBase64 = base64;
          this.vistaPrevia.set(base64);
        } else {
          const raw = e.target?.result as string;
          this.fotoBase64 = raw;
          this.vistaPrevia.set(raw);
        }
      };
      img.src = e.target?.result as string;
    };
    lector.readAsDataURL(archivo);
  }

  esInvalido(campo: keyof typeof this.publicacionForm.controls): boolean {
    const control = this.publicacionForm.controls[campo];
    return control.invalid && control.touched;
  }

  onSubmit(): void {
    this.errorMessage.set(null);

    if (this.publicacionForm.invalid) {
      this.publicacionForm.markAllAsTouched();
      return;
    }

    this.enviando.set(true);
    const valores = this.publicacionForm.getRawValue();
    const datos: INuevaPublicacion = {
      ...valores,
      edadAproximada: valores.edadAproximada.trim() || undefined,
      raza: valores.raza || undefined,
    };

    this.publicacionesResource.crearPublicacion(datos).subscribe({
      next: (resultado) => {
        if (this.fotoBase64 && typeof localStorage !== "undefined") {
          try {
            const nombreNormalizado = datos.nombre.trim().toLowerCase();
            localStorage.setItem(`foto_${nombreNormalizado}`, this.fotoBase64);

            const nroReg = resultado?.["nroRegMunicipal"];
            const nroPub = resultado?.["nroPublicacion"];
            if (nroReg) {
              localStorage.setItem(`foto_${nroReg}`, this.fotoBase64);
            }
            if (nroPub) {
              localStorage.setItem(`foto_${nroPub}`, this.fotoBase64);
            }
          } catch (e) {
            console.warn("No se pudo guardar la foto en localStorage:", e);
          }
        }

        this.enviando.set(false);
        this.publicada.emit();
      },
      error: (error) => {
        console.error("Error al crear la publicación:", error);
        this.enviando.set(false);
        if (error.status === 401) {
          return;
        }
        this.errorMessage.set(
          error.status === 403
            ? "No tiene permisos para realizar esta operación."
            : (error.error?.mensaje ??
                "No se pudo registrar la publicación. Intente nuevamente."),
        );
      },
    });
  }

  ngOnDestroy(): void {
    this.liberarVistaPrevia();
  }

  private liberarVistaPrevia(): void {
    const url = this.vistaPrevia();
    if (url && url.startsWith("blob:")) {
      URL.revokeObjectURL(url);
    }
    this.vistaPrevia.set(null);
  }
}
