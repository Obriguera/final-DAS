package ar.edu.ubp.das.mascotascbasoap.services;

import ar.edu.ubp.das.mascotascbasoap.be.CambioEstadoDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.CrearPublicacionDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.LoginDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.PublicacionBE;
import ar.edu.ubp.das.mascotascbasoap.be.ResultadoPublicacionBE;
import jakarta.jws.WebMethod;
import jakarta.jws.WebParam;
import jakarta.jws.WebResult;
import jakarta.jws.WebService;

import java.util.List;

@WebService(
        targetNamespace = "http://ws.mascotascba.das.ubp.edu.ar/"
)
public interface IMascotasCbaWebService {

    @WebMethod(operationName = "AutenticarUsuario")
    @WebResult(name = "loginData")
    LoginDataBE autenticar(
            @WebParam(name = "cuil") String cuil,
            @WebParam(name = "clave") String clave
    );

    @WebMethod(operationName = "ConsultarPublicaciones")
    @WebResult(name = "publicacion")
    List<PublicacionBE> getPublicaciones();

    @WebMethod(operationName = "ConsultarEspecies")
    @WebResult(name = "especie")
    List<String> getEspecies();

    @WebMethod(operationName = "ConsultarRazas")
    @WebResult(name = "raza")
    List<String> getRazas();

    @WebMethod(operationName = "ConsultarSexos")
    @WebResult(name = "sexo")
    List<String> getSexos();

    @WebMethod(operationName = "CrearPublicacion")
    @WebResult(name = "resultado")
    ResultadoPublicacionBE crearPublicacion(
            @WebParam(name = "datosPublicacion")
            CrearPublicacionDataBE datos
    );

    @WebMethod(operationName = "CambiarEstadoPublicacion")
    @WebResult(name = "estadoPublicacion")
    String cambiarEstado(
            @WebParam(name = "datosCambioEstado")
            CambioEstadoDataBE datos
    );
}