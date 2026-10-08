package ar.edu.ubp.das.mascotascbasoap.be;


import java.util.Date;

public class PublicacionBE {

    private String nroPublicacion;
    private String nroRegMunicipal;
    private String nombre;
    private String sexo;
    private String caracteristicasMascota;
    private String condicionAdopcion;
    private String foto;
    private String estadoPublicacion;
    private Date fechaPublicacion;

    public String getNroPublicacion() {
        return nroPublicacion;
    }

    public void setNroPublicacion(String nroPublicacion) {
        this.nroPublicacion = nroPublicacion;
    }

    public String getNroRegMunicipal() {
        return nroRegMunicipal;
    }

    public void setNroRegMunicipal(String nroRegMunicipal) {
        this.nroRegMunicipal = nroRegMunicipal;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getSexo() {
        return sexo;
    }

    public void setSexo(String sexo) {
        this.sexo = sexo;
    }

    public String getCaracteristicasMascota() {
        return caracteristicasMascota;
    }

    public void setCaracteristicasMascota(String caracteristicasMascota) {
        this.caracteristicasMascota = caracteristicasMascota;
    }

    public String getCondicionAdopcion() {
        return condicionAdopcion;
    }

    public void setCondicionAdopcion(String condicionAdopcion) {
        this.condicionAdopcion = condicionAdopcion;
    }

    public String getFoto() {
        return foto;
    }

    public void setFoto(String foto) {
        this.foto = foto;
    }

    public String getEstadoPublicacion() {
        return estadoPublicacion;
    }

    public void setEstadoPublicacion(String estadoPublicacion) {
        this.estadoPublicacion = estadoPublicacion;
    }

    public Date getFechaPublicacion() {
        return fechaPublicacion;
    }

    public void setFechaPublicacion(Date fechaPublicacion) {
        this.fechaPublicacion = fechaPublicacion;
    }
}