package ar.edu.ubp.das.mascotascbarest.resources;

import ar.edu.ubp.das.mascotascbarest.BE.LoginDataBE;
import ar.edu.ubp.das.mascotascbarest.repositories.LoginRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
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
    public ResponseEntity<LoginDataBE> login(@RequestBody LoginDataBE datos, HttpServletRequest request) {
        if (datos.getCuil() == null || datos.getCuil().isBlank()
                || datos.getClave() == null || datos.getClave().isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        LoginDataBE usuario = repository.autenticar(datos.getCuil().trim(), datos.getClave());

        if (usuario == null) {
            return ResponseEntity.status(401).build();
        }

        HttpSession session = request.getSession();
        request.changeSessionId();
        session.setAttribute("idCiudadano", usuario.getIdCiudadano());
        session.setAttribute("idRefugio", usuario.getIdRefugio());
        session.setAttribute("rol", usuario.getRol());

        return ResponseEntity.ok(usuario);
    }
}
