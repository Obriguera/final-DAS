import { Routes } from '@angular/router';
import { LoginComponent } from './pages/login-component/login-component';
import { PublicacionesComponent } from './pages/publicaciones-component/publicaciones-component';
import { refugioGuard } from './guards/refugio-guard';


export const routes: Routes = [
    { path:'', component: LoginComponent},
    { path:'publicaciones', component: PublicacionesComponent, canActivate: [refugioGuard]},
    { path:'**', redirectTo: '' }
];
