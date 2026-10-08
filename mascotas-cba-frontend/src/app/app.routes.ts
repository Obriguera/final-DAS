import { Routes } from '@angular/router';
import { LoginComponent } from './login-component/login-component';
import { Placeholder } from './placeholder/placeholder';


export const routes: Routes = [
    { path:'', component: LoginComponent},
    { path:'home', component: Placeholder},
    { path:'**', redirectTo: '' }
];
