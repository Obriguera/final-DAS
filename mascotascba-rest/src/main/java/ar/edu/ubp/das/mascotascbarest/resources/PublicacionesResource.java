package ar.edu.ubp.das.mascotascbarest.resources;

import ar.edu.ubp.das.mascotascbarest.BE.CambioEstadoDataBE;
import ar.edu.ubp.das.mascotascbarest.BE.CrearPublicacionDataBE;
import ar.edu.ubp.das.mascotascbarest.BE.PublicacionBE;
import ar.edu.ubp.das.mascotascbarest.repositories.PublicacionesRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/publicaciones")
public class PublicacionesResource {

    @Autowired
    private PublicacionesRepository repository;

    @GetMapping
    public ResponseEntity<List<PublicacionBE>> getPublicaciones(
            @RequestHeader("X-Id-Ciudadano") String idCiudadano,
            @RequestHeader("X-Id-Refugio") String idRefugio,
            @RequestParam(required = false) String nombre,
            @RequestParam(required = false) String estado) {

        return ResponseEntity.ok(
                repository.getPublicaciones(idCiudadano, idRefugio, nombre, estado)
        );
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> crearPublicacion(
            @RequestHeader("X-Id-Ciudadano") String idCiudadano,
            @RequestHeader("X-Id-Refugio") String idRefugio,
            @RequestBody CrearPublicacionDataBE datos) {

        Map<String, Object> resultado = repository.crearPublicacion(
                idCiudadano,
                idRefugio,
                datos.getNombre(),
                datos.getEspecie(),
                datos.getSexo(),
                datos.getEdadAproximada(),
                datos.getRaza(),
                datos.getCaracteristicasMascota(),
                datos.getCondicionAdopcion(),
                datos.getFoto()
        );

        if (!"OK".equals(resultado.get("resultado"))) {
            return ResponseEntity.status(estadoHttp(resultado)).body(resultado);
        }

        return ResponseEntity.status(201).body(resultado);
    }

    @PatchMapping("/estado")
    public ResponseEntity<Map<String, Object>> cambiarEstado(
            @RequestHeader("X-Id-Ciudadano") String idCiudadano,
            @RequestHeader("X-Id-Refugio") String idRefugio,
            @RequestBody CambioEstadoDataBE datos) {

        Map<String, Object> resultado = repository.cambiarEstado(
                datos.getNroPublicacion(),
                idCiudadano,
                idRefugio,
                datos.getAccion()
        );

        if (!"OK".equals(resultado.get("resultado"))) {
            return ResponseEntity.status(estadoHttp(resultado)).body(resultado);
        }

        return ResponseEntity.ok(resultado);
    }

    private int estadoHttp(Map<String, Object> resultado) {
        Object codigo = resultado.get("codigo");

        if ("NO_AUTORIZADO".equals(codigo)) {
            return 403;
        }
        if ("NO_ENCONTRADO".equals(codigo)) {
            return 404;
        }
        if ("ESTADO_INVALIDO".equals(codigo)) {
            return 409;
        }
        return 400;
    }
}