import { Component, OnDestroy, inject, output, signal } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { PublicacionesResource } from '../services/publicaciones-resource';

@Component({
  imports: [ReactiveFormsModule],
  selector: 'app-nueva-publicacion',
  styleUrl: './nueva-publicacion.scss',
  templateUrl: './nueva-publicacion.html',
})
export class NuevaPublicacion implements OnDestroy {
  // PublicacionesResource lo provee el componente padre
  private publicacionesResource = inject(PublicacionesResource);

  readonly publicada = output<void>();
  readonly cancelada = output<void>();

  readonly especies = ['Perro', 'Gato', 'Otro'];
  readonly sexos = ['Hembra', 'Macho'];

  errorMessage = signal<string | null>(null);
  enviando = signal(false);
  vistaPrevia = signal<string | null>(null);

  publicacionForm = new FormGroup({
    nombre: new FormControl<string>('', {
      nonNullable: true,
      validators: [Validators.required, Validators.maxLength(100)],
    }),
    especie: new FormControl<string>('', { nonNullable: true, validators: [Validators.required] }),
    sexo: new FormControl<string>('', { nonNullable: true, validators: [Validators.required] }),
    edadAproximada: new FormControl<string>('', {
      nonNullable: true,
      validators: [Validators.pattern(/^\s*\d+(\s+\D.*)?$/)],
    }),
    raza: new FormControl<string>('', { nonNullable: true, validators: [Validators.maxLength(200)] }),
    caracteristicasMascota: new FormControl<string>('', {
      nonNullable: true,
      validators: [Validators.required, Validators.maxLength(500)],
    }),
    condicionAdopcion: new FormControl<string>('', {
      nonNullable: true,
      validators: [Validators.required, Validators.maxLength(300)],
    }),
    // Guarda el nombre del archivo seleccionado, que es lo que recibe el backend
    foto: new FormControl<string>('', {
      nonNullable: true,
      validators: [Validators.required, Validators.maxLength(300)],
    }),
  });

  onFotoSeleccionada(event: Event): void {
    const archivo = (event.target as HTMLInputElement).files?.[0];
    this.liberarVistaPrevia();

    if (!archivo) {
      this.publicacionForm.controls.foto.setValue('');
    } else {
      this.publicacionForm.controls.foto.setValue(archivo.name);
      this.vistaPrevia.set(URL.createObjectURL(archivo));
    }
    this.publicacionForm.controls.foto.markAsTouched();
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
    this.publicacionesResource.crearPublicacion(this.publicacionForm.getRawValue()).subscribe({
      next: () => {
        this.enviando.set(false);
        this.publicada.emit();
      },
      error: (error) => {
        console.error('Error al crear la publicación:', error);
        this.enviando.set(false);
        this.errorMessage.set(error.error?.mensaje ?? 'No se pudo registrar la publicación. Intente nuevamente.');
      },
    });
  }

  ngOnDestroy(): void {
    this.liberarVistaPrevia();
  }

  private liberarVistaPrevia(): void {
    const url = this.vistaPrevia();
    if (url) {
      URL.revokeObjectURL(url);
      this.vistaPrevia.set(null);
    }
  }
}
