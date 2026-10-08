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

    public List<PublicacionBE> getPublicaciones(
            String idCiudadano,
            String idRefugio,
            String nombre,
            String estado) {

        return jdbcTemplate.query(
                "exec dbo.get_publicaciones @id_ciudadano=?, @id_refugio=?, @nombre=?, @estado=?",
                new BeanPropertyRowMapper<>(PublicacionBE.class),
                idCiudadano,
                idRefugio,
                nombre,
                estado
        );
    }

    public Map<String, Object> crearPublicacion(
            String idCiudadano,
            String idRefugio,
            String nombre,
            String especie,
            String sexo,
            String edadAproximada,
            String raza,
            String descripcion,
            String condiciones,
            String foto) {

        return jdbcTemplate.queryForMap(
                "exec dbo.crear_publicacion "
                        + "@id_ciudadano=?, @id_refugio=?, @nombre=?, @especie=?, @sexo=?, "
                        + "@edad_aproximada=?, @raza=?, @caracteristicas_mascota=?, "
                        + "@condicion_adopcion=?, @foto=?",
                idCiudadano,
                idRefugio,
                nombre,
                especie,
                sexo,
                edadAproximada,
                raza,
                descripcion,
                condiciones,
                foto
        );
    }

    public Map<String, Object> cambiarEstado(
            String nroPublicacion,
            String idCiudadano,
            String idRefugio,
            String accion) {

        return jdbcTemplate.queryForMap(
                "exec dbo.act_estado_publicacion @nro_publicacion=?, @id_ciudadano=?, @id_refugio=?, @accion=?",
                nroPublicacion,
                idCiudadano,
                idRefugio,
                accion
        );
    }
}
