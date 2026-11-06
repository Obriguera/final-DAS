package ar.edu.ubp.das.mascotascbasoap.be;

public class ResultadoPublicacionBE {

    private Integer nroPublicacion;
    private String nroRegMunicipal;
    private String estadoPublicacion;

    public Integer getNroPublicacion() {
        return nroPublicacion;
    }

    public void setNroPublicacion(Integer nroPublicacion) {
        this.nroPublicacion = nroPublicacion;
    }

    public String getNroRegMunicipal() {
        return nroRegMunicipal;
    }

    public void setNroRegMunicipal(String nroRegMunicipal) {
        this.nroRegMunicipal = nroRegMunicipal;
    }

    public String getEstadoPublicacion() {
        return estadoPublicacion;
    }

    public void setEstadoPublicacion(String estadoPublicacion) {
        this.estadoPublicacion = estadoPublicacion;
    }
}