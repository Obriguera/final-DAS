import { Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { LoginResource } from '../../services/login-resource';
import { SesionService } from '../../services/sesion-service';
import { Router } from '@angular/router';

@Component({
  imports: [ReactiveFormsModule],
  providers: [LoginResource],
  selector: 'app-login-component',
  styleUrl: './login-component.scss',
  templateUrl: './login-component.html',
})
export class LoginComponent {
  
  private loginResource = inject(LoginResource);
  private router = inject(Router);
  private sesion = inject(SesionService);


  errorMessage = signal<string | null>(null);



  loginForm = new FormGroup({
    cuil: new FormControl<string>('', {
      nonNullable: true,
      validators: [
        Validators.required,
        Validators.pattern(/^\d{11}$/)
      ]
    }),
    
    clave: new FormControl<string>('', {
      nonNullable: true,
      validators: [Validators.required, Validators.minLength(6)],
    }),
  });

  onSubmit(): void {
    this.errorMessage.set(null); // Vacio el mensaje de error

    if (this.loginForm.valid) {
      const { cuil, clave } = this.loginForm.getRawValue();
      this.loginResource.login(cuil, clave).subscribe({
        next: (response) => {
          // Por ahora la aplicación solo contempla el perfil Refugio
          if (response.rol !== 'REFUGIO' || !response.idRefugio) {
            this.errorMessage.set('Solo los usuarios de refugios pueden ingresar a la aplicación.')
            return;
          }

          this.sesion.setSesion({
            cuil,
            idCiudadano: response.idCiudadano,
            idRefugio: response.idRefugio,
            razonSocial: response.razonSocial,
            rol: response.rol
          });
          this.router.navigate(['/publicaciones'])
        },
        error: (error) => {
          console.error('Error en la autenticación:', error);

          if(error.status === 401){
            this.errorMessage.set('El CUIL o la clave ingresada son incorrectos.')
          } else {
            this.errorMessage.set('No se pudo conectar con el servidor. Intente nuevamente.')
          }

        }
      });
    } else {
      this.loginForm.markAllAsTouched();
    }
  }
}
