package ar.edu.ubp.das.mascotascbasoap.repositories;


import ar.edu.ubp.das.mascotascbasoap.be.CambioEstadoDataBE;
import ar.edu.ubp.das.mascotascbasoap.be.PublicacionBE;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class PublicacionesRepository {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public List<PublicacionBE> getPublicaciones(String idRefugio, String nombre, String estado) {
        return jdbcTemplate.query(
                "exec dbo.get_publicaciones ?, ?, ?",
                new BeanPropertyRowMapper<>(PublicacionBE.class),
                idRefugio,
                nombre,
                estado
        );
    }

    public void cambiarEstado(CambioEstadoDataBE datos) {
        jdbcTemplate.update(
                "exec dbo.act_estado_publicacion ?, ?",
                datos.getNroPublicacion(),
                datos.getAccion()
        );
    }
}
