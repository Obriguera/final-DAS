import { Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { LoginResource } from '../services/login-resource';
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
        
          localStorage.setItem('sesion', JSON.stringify(response))
          this.router.navigate(['/home'])

        },
        error: (error) => {
          console.error('Error en la autenticación:', error);

          if(error.status === 401){
            this.errorMessage.set('El CUIL o la clave ingresada son incorrectos.')
          }

        }
      });
    } else {
      this.loginForm.markAllAsTouched();
    }
  }
}
