package ar.edu.ubp.das.mascotascbarest.BE;

public class CrearPublicacionDataBE {

    private String nombre;
    private String especie;
    private String sexo;
    private String edadAproximada;
    private String raza;
    private String caracteristicasMascota;
    private String condicionAdopcion;
    private String foto;

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getEspecie() {
        return especie;
    }

    public void setEspecie(String especie) {
        this.especie = especie;
    }

    public String getSexo() {
        return sexo;
    }

    public void setSexo(String sexo) {
        this.sexo = sexo;
    }

    public String getEdadAproximada() {
        return edadAproximada;
    }

    public void setEdadAproximada(String edadAproximada) {
        this.edadAproximada = edadAproximada;
    }

    public String getRaza() {
        return raza;
    }

    public void setRaza(String raza) {
        this.raza = raza;
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
}