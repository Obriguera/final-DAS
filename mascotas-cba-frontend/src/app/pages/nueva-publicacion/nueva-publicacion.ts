import {
  Component,
  OnDestroy,
  computed,
  input,
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
} from "../../services/publicaciones-resource";

@Component({
  imports: [ReactiveFormsModule],
  selector: "app-nueva-publicacion",
  styleUrl: "./nueva-publicacion.scss",
  templateUrl: "./nueva-publicacion.html",
})
export class NuevaPublicacion implements OnDestroy {
  // Inputs basados en signals para mantener el componente desacoplado del backend
  readonly especies = input<string[]>([]);
  readonly razas = input<string[]>([]);
  readonly sexos = input<ISexo[]>([]);
  readonly enviando = input<boolean>(false);
  readonly errorMessage = input<string | null>(null);

  readonly guardar = output<{
    datos: INuevaPublicacion;
    fotoBase64: string | null;
  }>();
  readonly cancelada = output<void>();

  vistaPrevia = signal<string | null>(null);
  private fotoBase64: string | null = null;

  // Estado del selector de año tipo calendario
  mostrarCalendarioAnio = signal(false);
  readonly anioMaximo: number = new Date().getFullYear();
  readonly anioMinimo: number = 1995;
  decadaActual = signal(Math.floor(new Date().getFullYear() / 10) * 10);

  aniosDecada = computed(() => {
    const decada = this.decadaActual();
    const anios: number[] = [];
    for (let i = 0; i < 12; i++) {
      anios.push(decada + i);
    }
    return anios;
  });

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
    anioNacimiento: new FormControl<number | null>(null, [
      Validators.min(1995),
      Validators.max(new Date().getFullYear()),
    ]),
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

  toggleCalendarioAnio(): void {
    this.mostrarCalendarioAnio.update((v) => !v);
  }

  navegarDecada(delta: number): void {
    this.decadaActual.update((d) => d + delta * 10);
  }

  seleccionarAnio(anio: number): void {
    this.publicacionForm.controls.anioNacimiento.setValue(anio);
    this.publicacionForm.controls.anioNacimiento.markAsTouched();
    this.mostrarCalendarioAnio.set(false);
  }

  limpiarAnio(event?: Event): void {
    if (event) {
      event.stopPropagation();
    }
    this.publicacionForm.controls.anioNacimiento.setValue(null);
    this.publicacionForm.controls.anioNacimiento.markAsTouched();
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
    if (this.publicacionForm.invalid) {
      this.publicacionForm.markAllAsTouched();
      return;
    }

    const valores = this.publicacionForm.getRawValue();
    const anio = valores.anioNacimiento;
    const edadCalculada = anio ? this.anioMaximo - anio : null;
    const edadAproximada =
      edadCalculada !== null && edadCalculada >= 0
        ? `${edadCalculada} anios`
        : undefined;

    const datos: INuevaPublicacion = {
      nombre: valores.nombre.trim(),
      especie: valores.especie,
      sexo: valores.sexo,
      anioNacimiento: anio,
      edadAproximada,
      raza: valores.raza ? valores.raza.trim() : undefined,
      caracteristicasMascota: valores.caracteristicasMascota.trim(),
      condicionAdopcion: valores.condicionAdopcion.trim(),
      foto: valores.foto,
    };

    this.guardar.emit({
      datos,
      fotoBase64: this.fotoBase64,
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
