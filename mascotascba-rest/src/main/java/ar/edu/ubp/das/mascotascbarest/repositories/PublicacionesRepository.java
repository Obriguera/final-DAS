package ar.edu.ubp.das.mascotascbarest.repositories;

import ar.edu.ubp.das.mascotascbarest.BE.PublicacionBE;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public class PublicacionesRepository {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public List<String> getEspecies() {
        return jdbcTemplate.queryForList("exec dbo.get_especies", String.class);
    }

    public List<String> getRazas() {
        return jdbcTemplate.queryForList("exec dbo.get_razas", String.class);
    }

    public List<PublicacionBE> getPublicaciones(int idRefugio) {
        return jdbcTemplate.query(
                "exec dbo.get_publicaciones @id_refugio=?",
                new BeanPropertyRowMapper<>(PublicacionBE.class),
                idRefugio
        );
    }

    public Map<String, Object> crearPublicacion(
            int idRefugio,
            String nombre,
            String sexo,
            Integer anioNacimiento,
            String especie,
            String raza,
            String caracteristicasMascota,
            String condicionAdopcion,
            String foto) {

        return jdbcTemplate.queryForMap(
                "exec dbo.crear_publicacion "
                        + "@id_refugio=?, @nombre=?, @sexo=?, @anio_nacimiento=?, @especie=?, @raza=?, "
                        + "@caracteristicas_mascota=?, @condicion_adopcion=?, @foto=?",
                idRefugio,
                nombre,
                sexo,
                anioNacimiento,
                especie,
                raza,
                caracteristicasMascota,
                condicionAdopcion,
                foto
        );
    }

    public String getEstado(int nroPublicacion, int idRefugio) {
        List<String> estados = jdbcTemplate.queryForList(
                "exec dbo.get_estado_publicacion @nro_publicacion=?, @id_refugio=?",
                String.class,
                nroPublicacion,
                idRefugio
        );

        return estados.isEmpty() ? null : estados.get(0);
    }

    public boolean cambiarEstado(int nroPublicacion, int idRefugio, String estadoActual, String estadoNuevo) {
        Integer filas = jdbcTemplate.queryForObject(
                "exec dbo.act_estado_publicacion "
                        + "@nro_publicacion=?, @id_refugio=?, @estado_actual=?, @estado_nuevo=?",
                Integer.class,
                nroPublicacion,
                idRefugio,
                estadoActual,
                estadoNuevo
        );

        return filas != null && filas > 0;
    }
}
