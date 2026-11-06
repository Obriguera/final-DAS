package ar.edu.ubp.das.mascotascbarest.resources;

import ar.edu.ubp.das.mascotascbarest.BE.CambioEstadoDataBE;
import ar.edu.ubp.das.mascotascbarest.BE.CrearPublicacionDataBE;
import ar.edu.ubp.das.mascotascbarest.BE.PublicacionBE;
import ar.edu.ubp.das.mascotascbarest.repositories.PublicacionesRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.Year;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/publicaciones")
public class PublicacionesResource {

    // "2", "2 anios", "6 meses"
    private static final Pattern EDAD =
            Pattern.compile("(\\d{1,3})\\s*(meses|mes|anios|anio|años|año)?", Pattern.CASE_INSENSITIVE);

    @Autowired
    private PublicacionesRepository repository;

    @GetMapping("/especies")
    public ResponseEntity<List<String>> getEspecies() {
        return ResponseEntity.ok(repository.getEspecies());
    }

    @GetMapping("/razas")
    public ResponseEntity<List<String>> getRazas() {
        return ResponseEntity.ok(repository.getRazas());
    }

    @GetMapping("/sexos")
    public ResponseEntity<List<Map<String, String>>> getSexos() {
        return ResponseEntity.ok(List.of(
                Map.of("codigo", "H", "nombre", "Hembra"),
                Map.of("codigo", "M", "nombre", "Macho")
        ));
    }

    @GetMapping
    public ResponseEntity<List<PublicacionBE>> getPublicaciones(HttpServletRequest request) {
        return ResponseEntity.ok(repository.getPublicaciones(idRefugio(request)));
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> crearPublicacion(
            HttpServletRequest request,
            @RequestBody CrearPublicacionDataBE datos) {

        int idRefugio = idRefugio(request);

        String nombre = texto(datos.getNombre());
        String sexo = texto(datos.getSexo()).toUpperCase();
        String especie = texto(datos.getEspecie());
        String raza = texto(datos.getRaza());
        String edad = texto(datos.getEdadAproximada());
        String descripcion = texto(datos.getCaracteristicasMascota());
        String condiciones = texto(datos.getCondicionAdopcion());
        String foto = texto(datos.getFoto());

        if (!sexo.isEmpty()) {
            sexo = sexo.substring(0, 1);   // acepta "H" o "Hembra", "M" o "Macho"
        }

        if (nombre.isEmpty() || nombre.length() > 100) {
            return error(400, "El nombre es obligatorio (maximo 100 caracteres)");
        }
        if (!sexo.equals("H") && !sexo.equals("M")) {
            return error(400, "El sexo debe ser Hembra o Macho");
        }
        if (descripcion.isEmpty() || descripcion.length() > 500) {
            return error(400, "La descripcion es obligatoria (maximo 500 caracteres)");
        }
        if (condiciones.isEmpty() || condiciones.length() > 300) {
            return error(400, "Las condiciones de adopcion son obligatorias (maximo 300 caracteres)");
        }
        if (foto.isEmpty() || foto.length() > 300) {
            return error(400, "La fotografia es obligatoria");
        }
        if (!repository.getEspecies().contains(especie)) {
            return error(400, "Especie invalida");
        }
        if (!raza.isEmpty() && !repository.getRazas().contains(raza)) {
            return error(400, "Raza invalida");
        }

        Integer anioNacimiento = null;
        if (!edad.isEmpty()) {
            Matcher m = EDAD.matcher(edad);
            if (!m.matches()) {
                return error(400, "La edad aproximada no es valida (ej: 2 anios, 6 meses)");
            }
            int anios = Integer.parseInt(m.group(1));
            if (m.group(2) != null && m.group(2).toLowerCase().startsWith("mes")) {
                anios = anios / 12;
            }
            if (anios > 40) {
                return error(400, "La edad aproximada no es valida (ej: 2 anios, 6 meses)");
            }
            anioNacimiento = Year.now().getValue() - anios;
        }

        Map<String, Object> resultado = repository.crearPublicacion(
                idRefugio,
                nombre,
                sexo,
                anioNacimiento,
                especie,
                raza.isEmpty() ? null : raza,
                descripcion,
                condiciones,
                foto
        );

        return ResponseEntity.status(201).body(resultado);
    }

    @PatchMapping("/estado")
    public ResponseEntity<Map<String, Object>> cambiarEstado(
            HttpServletRequest request,
            @RequestBody CambioEstadoDataBE datos) {

        int idRefugio = idRefugio(request);
        String accion = texto(datos.getAccion()).toUpperCase();

        if (datos.getNroPublicacion() == null
                || !List.of("ACTIVAR", "PAUSAR", "FINALIZAR").contains(accion)) {
            return error(400, "La publicacion y la accion (ACTIVAR, PAUSAR o FINALIZAR) son obligatorias");
        }

        String actual = repository.getEstado(datos.getNroPublicacion(), idRefugio);
        if (actual == null) {
            return error(404, "La publicacion no existe");
        }

        String nuevo = switch (accion) {
            case "ACTIVAR" -> actual.equals("PAUSADA") ? "ACTIVA" : null;
            case "PAUSAR" -> actual.equals("ACTIVA") ? "PAUSADA" : null;
            default -> actual.equals("ACTIVA") || actual.equals("PAUSADA") ? "FINALIZADA" : null;
        };

        if (nuevo == null) {
            return error(409, "Accion no permitida para el estado actual");
        }
        if (!repository.cambiarEstado(datos.getNroPublicacion(), idRefugio, actual, nuevo)) {
            return error(409, "La publicacion cambio de estado, actualice el listado");
        }

        return ResponseEntity.ok(Map.of("estadoPublicacion", nuevo));
    }

    // El refugio sale unicamente de la sesion creada en el login.
    private int idRefugio(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        if (session == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }

        Object idRefugio = session.getAttribute("idRefugio");
        if (!"REFUGIO".equals(session.getAttribute("rol")) || idRefugio == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }

        return (Integer) idRefugio;
    }

    private String texto(String valor) {
        return valor == null ? "" : valor.trim();
    }

    private ResponseEntity<Map<String, Object>> error(int estado, String mensaje) {
        return ResponseEntity.status(estado).body(Map.of("mensaje", mensaje));
    }
}
