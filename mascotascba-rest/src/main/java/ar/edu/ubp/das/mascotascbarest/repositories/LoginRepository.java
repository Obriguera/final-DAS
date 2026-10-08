package ar.edu.ubp.das.mascotascbarest.repositories;

import ar.edu.ubp.das.mascotascbarest.BE.LoginDataBE;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class LoginRepository {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public LoginDataBE autenticar(String cuil, String clave) {
        List<LoginDataBE> resultado = jdbcTemplate.query(
                "exec dbo.aut_usuario @cuil=?, @clave=?",
                new BeanPropertyRowMapper<>(LoginDataBE.class),
                cuil,
                clave
        );

        return resultado.isEmpty() ? null : resultado.get(0);
    }
}