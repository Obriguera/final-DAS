package ar.edu.ubp.das.mascotascbasoap.services;

import ar.edu.ubp.das.mascotascbasoap.be.CambioEstadoDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.LoginDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.PublicacionBE;

// Cambio de javax a jakarta
import jakarta.jws.WebMethod;
import jakarta.jws.WebParam;
import jakarta.jws.WebResult;
import jakarta.jws.WebService;
import java.util.List;

@WebService(targetNamespace = "http://ws.mascotascba.das.ubp.edu.ar/")
public interface IMascotasCbaWebService {

    @WebMethod(operationName = "AutenticarUsuario")
    @WebResult(name = "loginData")
    LoginDataBE autenticar(
            @WebParam(name = "cuil") String cuil,
            @WebParam(name = "clave") String clave
    );

    @WebMethod(operationName = "ConsultarPublicaciones")
    @WebResult(name = "publicacion")
    List<PublicacionBE> getPublicaciones(
            @WebParam(name = "idRefugio") String idRefugio,
            @WebParam(name = "nombre") String nombre,
            @WebParam(name = "estado") String estado
    );

    @WebMethod(operationName = "CambiarEstadoPublicacion")
    void cambiarEstado(
            @WebParam(name = "datosCambioEstado") CambioEstadoDataBE datos
    );
}