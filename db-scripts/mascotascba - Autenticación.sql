USE mascotascba;
GO

/* ---------- Login ---------- */

CREATE OR ALTER PROCEDURE dbo.aut_usuario
(
    @cuil  VARCHAR(20),
    @clave VARCHAR(200)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.id_ciudadano,
        c.apellido,
        c.nombre,
        r.nombre AS rol,
        f.id_refugio,
        f.razon_social
    FROM dbo.ciudadanos c

    INNER JOIN dbo.roles r
        ON r.id_rol = c.id_rol

    LEFT JOIN dbo.refugios f
        ON f.id_responsable = c.id_ciudadano
        AND r.nombre = 'REFUGIO'

    WHERE c.cuil = @cuil
      AND c.clave COLLATE Latin1_General_CS_AS =
          @clave COLLATE Latin1_General_CS_AS
      AND c.habilitado = 'S';
END;
GO

-- REFUGIO
-- exec dbo.aut_usuario @cuil='27456789012', @clave='clave300001'   
-- VETERINARIA
-- exec dbo.aut_usuario @cuil='20178901234', @clave='clave200001' 
-- CIUDADANO
-- exec dbo.aut_usuario @cuil='20123456789', @clave='clave100001'   
-- INVALIDO
-- exec dbo.aut_usuario @cuil='27456789012', @clave='incorrecta'    