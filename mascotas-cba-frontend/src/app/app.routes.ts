import { Routes } from '@angular/router';
import { LoginComponent } from './login-component/login-component';
import { PublicacionesComponent } from './publicaciones-component/publicaciones-component';
import { refugioGuard } from './guards/refugio-guard';


export const routes: Routes = [
    { path:'', component: LoginComponent},
    { path:'publicaciones', component: PublicacionesComponent, canActivate: [refugioGuard]},
    { path:'**', redirectTo: '' }
];
