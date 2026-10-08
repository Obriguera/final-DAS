import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { LoginResource } from './login-resource';

describe('LoginResource', () => {
  let service: LoginResource;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [LoginResource, provideHttpClient(), provideHttpClientTesting()]
    });
    service = TestBed.inject(LoginResource);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
