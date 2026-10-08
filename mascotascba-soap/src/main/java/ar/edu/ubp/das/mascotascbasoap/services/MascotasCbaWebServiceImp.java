package ar.edu.ubp.das.mascotascbasoap.services;

import ar.edu.ubp.das.mascotascbasoap.be.CambioEstadoDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.LoginDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.PublicacionBE;
import ar.edu.ubp.das.mascotascbasoap.repositories.LoginRepository;
import ar.edu.ubp.das.mascotascbasoap.repositories.PublicacionesRepository;
import jakarta.jws.WebService; // Cambio a jakarta
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional; // Import para transacciones
import java.util.List;

@Service
@WebService(
        endpointInterface = "ar.edu.ubp.das.mascotascbasoap.services.IMascotasCbaWebService",
        targetNamespace = "http://ws.mascotascba.das.ubp.edu.ar/"
)
public class MascotasCbaWebServiceImp implements IMascotasCbaWebService {

    private final LoginRepository loginRepository;
    private final PublicacionesRepository publicacionesRepository;

    // Inyección por constructor recomendada
    public MascotasCbaWebServiceImp(LoginRepository loginRepository, PublicacionesRepository publicacionesRepository) {
        this.loginRepository = loginRepository;
        this.publicacionesRepository = publicacionesRepository;
    }

    @Override
    public LoginDataBE autenticar(String cuil, String clave) {
        return loginRepository.autenticar(cuil, clave);
    }

    @Override
    public List<PublicacionBE> getPublicaciones(String idRefugio, String nombre, String estado) {
        return publicacionesRepository.getPublicaciones(idRefugio, nombre, estado);
    }

    @Override
    @Transactional // Operación de modificación de estado
    public void cambiarEstado(CambioEstadoDataBE datos) {
        publicacionesRepository.cambiarEstado(datos);
    }
}