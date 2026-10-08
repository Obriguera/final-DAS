package ar.edu.ubp.das.mascotascbarest.resources;

import ar.edu.ubp.das.mascotascbarest.BE.LoginDataBE;
import ar.edu.ubp.das.mascotascbarest.repositories.LoginRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/login")
public class LoginResource {

    @Autowired
    private LoginRepository repository;

    @PostMapping
    public ResponseEntity<LoginDataBE> login(@RequestBody LoginDataBE datos) {
        LoginDataBE sesion = repository.autenticar(datos.getCuil(), datos.getClave());

        if (sesion == null) {
            return ResponseEntity.status(401).build();
        }

        sesion.setClave(null);

        return ResponseEntity.ok(sesion);
    }
}
