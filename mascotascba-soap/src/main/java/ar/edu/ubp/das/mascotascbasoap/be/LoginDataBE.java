package ar.edu.ubp.das.mascotascbasoap.be;

public class LoginDataBE {
    private String cuil;
    private String clave;
    private String idCiudadano;
    private String idRefugio;
    private String razonSocial;

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

    public String getIdCiudadano() {
        return idCiudadano;
    }

    public void setIdCiudadano(String idCiudadano) {
        this.idCiudadano = idCiudadano;
    }

    public String getIdRefugio() {
        return idRefugio;
    }

    public void setIdRefugio(String idRefugio) {
        this.idRefugio = idRefugio;
    }

    public String getRazonSocial() {
        return razonSocial;
    }

    public void setRazonSocial(String razonSocial) {
        this.razonSocial = razonSocial;
    }
}