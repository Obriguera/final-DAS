package ar.edu.ubp.das.mascotascbasoap.services;

import ar.edu.ubp.das.mascotascbasoap.be.CambioEstadoDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.CrearPublicacionDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.LoginDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.PublicacionBE;
import ar.edu.ubp.das.mascotascbasoap.be.ResultadoPublicacionBE;
import ar.edu.ubp.das.mascotascbasoap.repositories.LoginRepository;
import ar.edu.ubp.das.mascotascbasoap.repositories.PublicacionesRepository;
import jakarta.annotation.Resource;
import jakarta.jws.WebService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import jakarta.xml.ws.WebServiceContext;
import jakarta.xml.ws.handler.MessageContext;
import org.springframework.stereotype.Service;

import java.time.Year;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@WebService(
        endpointInterface =
                "ar.edu.ubp.das.mascotascbasoap.services.IMascotasCbaWebService",
        targetNamespace =
                "http://ws.mascotascba.das.ubp.edu.ar/"
)
public class MascotasCbaWebServiceImp
        implements IMascotasCbaWebService {

    private static final Pattern EDAD =
            Pattern.compile(
                    "(\\d{1,3})\\s*(meses|mes|anios|anio|años|año)?",
                    Pattern.CASE_INSENSITIVE
            );

    private final LoginRepository loginRepository;
    private final PublicacionesRepository publicacionesRepository;

    @Resource
    private WebServiceContext webServiceContext;

    public MascotasCbaWebServiceImp(
            LoginRepository loginRepository,
            PublicacionesRepository publicacionesRepository) {

        this.loginRepository = loginRepository;
        this.publicacionesRepository = publicacionesRepository;
    }

    @Override
    public LoginDataBE autenticar(
            String cuil,
            String clave) {

        LoginDataBE usuario =
                loginRepository.autenticar(cuil, clave);

        if (usuario == null) {
            return null;
        }

        HttpServletRequest request = request();

        HttpSession session = request.getSession();

        request.changeSessionId();

        session.setAttribute(
                "idCiudadano",
                usuario.getIdCiudadano()
        );

        session.setAttribute(
                "idRefugio",
                usuario.getIdRefugio()
        );

        session.setAttribute(
                "rol",
                usuario.getRol()
        );

        return usuario;
    }

    @Override
    public List<PublicacionBE> getPublicaciones() {

        return publicacionesRepository.getPublicaciones(
                idRefugio()
        );
    }

    @Override
    public List<String> getEspecies() {
        return publicacionesRepository.getEspecies();
    }

    @Override
    public List<String> getRazas() {
        return publicacionesRepository.getRazas();
    }

    @Override
    public List<String> getSexos() {
        return List.of("H", "M");
    }

    @Override
    public ResultadoPublicacionBE crearPublicacion(
            CrearPublicacionDataBE datos) {

        int idRefugio = idRefugio();

        String nombre = texto(datos.getNombre());

        String sexo =
                texto(datos.getSexo()).toUpperCase();

        if (!sexo.isEmpty()) {
            sexo = sexo.substring(0, 1);
        }

        String especie =
                texto(datos.getEspecie());

        String raza =
                texto(datos.getRaza());

        String descripcion =
                texto(datos.getCaracteristicasMascota());

        String condiciones =
                texto(datos.getCondicionAdopcion());

        String foto =
                texto(datos.getFoto());

        Integer anioNacimiento =
                calcularAnioNacimiento(
                        datos.getEdadAproximada()
                );

        return publicacionesRepository.crearPublicacion(
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
    }

    @Override
    public String cambiarEstado(
            CambioEstadoDataBE datos) {

        int idRefugio = idRefugio();

        int nroPublicacion =
                datos.getNroPublicacion();

        String accion =
                texto(datos.getAccion()).toUpperCase();

        String estadoActual =
                publicacionesRepository.getEstado(
                        nroPublicacion,
                        idRefugio
                );

        if (estadoActual == null) {
            return null;
        }

        String estadoNuevo = switch (accion) {

            case "ACTIVAR" ->
                    estadoActual.equals("PAUSADA")
                            ? "ACTIVA"
                            : null;

            case "PAUSAR" ->
                    estadoActual.equals("ACTIVA")
                            ? "PAUSADA"
                            : null;

            case "FINALIZAR" ->
                    estadoActual.equals("ACTIVA")
                            || estadoActual.equals("PAUSADA")
                            ? "FINALIZADA"
                            : null;

            default -> null;
        };

        if (estadoNuevo == null) {
            return null;
        }

        boolean actualizado =
                publicacionesRepository.cambiarEstado(
                        nroPublicacion,
                        idRefugio,
                        estadoActual,
                        estadoNuevo
                );

        return actualizado
                ? estadoNuevo
                : null;
    }

    private HttpServletRequest request() {

        MessageContext context =
                webServiceContext.getMessageContext();

        return (HttpServletRequest)
                context.get(
                        MessageContext.SERVLET_REQUEST
                );
    }

    private int idRefugio() {

        HttpSession session =
                request().getSession(false);

        if (session == null) {
            throw new IllegalStateException(
                    "Sesion no iniciada"
            );
        }

        Object rol =
                session.getAttribute("rol");

        Object idRefugio =
                session.getAttribute("idRefugio");

        if (!"REFUGIO".equals(rol)
                || idRefugio == null) {

            throw new IllegalStateException(
                    "Usuario no autorizado"
            );
        }

        return (Integer) idRefugio;
    }

    private Integer calcularAnioNacimiento(
            String edadAproximada) {

        String edad = texto(edadAproximada);

        if (edad.isEmpty()) {
            return null;
        }

        Matcher matcher = EDAD.matcher(edad);

        if (!matcher.matches()) {
            throw new IllegalArgumentException(
                    "Edad aproximada invalida"
            );
        }

        int anios =
                Integer.parseInt(matcher.group(1));

        if (matcher.group(2) != null
                && matcher.group(2)
                .toLowerCase()
                .startsWith("mes")) {

            anios = anios / 12;
        }

        if (anios > 40) {
            throw new IllegalArgumentException(
                    "Edad aproximada invalida"
            );
        }

        return Year.now().getValue() - anios;
    }

    private String texto(String valor) {
        return valor == null
                ? ""
                : valor.trim();
    }
}