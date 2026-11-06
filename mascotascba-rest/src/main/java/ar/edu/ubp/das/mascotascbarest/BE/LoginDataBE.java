package ar.edu.ubp.das.mascotascbarest.BE;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

public class LoginDataBE {

    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String cuil;
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String clave;
    @JsonIgnore
    private Integer idCiudadano;
    @JsonIgnore
    private Integer idRefugio;
    private String apellido;
    private String nombre;
    private String razonSocial;
    private String rol;

    public String getCuil() {
        return cuil;
    }

    public void setCuil(String cuil) {
        this.cuil = cuil;
    }

    public String getClave() {
        return clave;
    }

    public void setClave(String clave) {
        this.clave = clave;
    }

    public Integer getIdCiudadano() {
        return idCiudadano;
    }

    public void setIdCiudadano(Integer idCiudadano) {
        this.idCiudadano = idCiudadano;
    }

    public Integer getIdRefugio() {
        return idRefugio;
    }

    public void setIdRefugio(Integer idRefugio) {
        this.idRefugio = idRefugio;
    }

    public String getApellido() {
        return apellido;
    }

    public void setApellido(String apellido) {
        this.apellido = apellido;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getRazonSocial() {
        return razonSocial;
    }

    public void setRazonSocial(String razonSocial) {
        this.razonSocial = razonSocial;
    }

    public String getRol() {
        return rol;
    }

    public void setRol(String rol) {
        this.rol = rol;
    }

}
