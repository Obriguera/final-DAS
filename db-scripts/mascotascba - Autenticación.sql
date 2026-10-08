USE mascotascba;
GO


CREATE OR ALTER PROCEDURE dbo.aut_usuario
(
    @cuil  VARCHAR(20),
    @clave VARCHAR(200)
)
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @id_ciudadano INT;
    DECLARE @id_refugio INT;
    DECLARE @id_veterinaria INT;
    DECLARE @rol VARCHAR(30);

    SELECT
        @id_ciudadano = c.id_ciudadano
    FROM dbo.ciudadanos c
    WHERE c.cuil = @cuil
      AND c.clave COLLATE Latin1_General_CS_AS = @clave COLLATE Latin1_General_CS_AS
      AND c.habilitado = 'S';

    IF @id_ciudadano IS NULL
    BEGIN
        SELECT
            idCiudadano   = CAST(NULL AS VARCHAR(1024)),
            idRefugio     = CAST(NULL AS VARCHAR(1024)),
            idVeterinaria = CAST(NULL AS VARCHAR(1024)),
            razonSocial   = CAST(NULL AS VARCHAR(150)),
            rol           = CAST(NULL AS VARCHAR(30))
        WHERE 1 = 0;
        RETURN;
    END;

    SELECT TOP 1
        @id_refugio = r.id_refugio
    FROM dbo.refugios r
    WHERE r.id_responsable = @id_ciudadano
    ORDER BY r.id_refugio;

    IF @id_refugio IS NOT NULL
    BEGIN
        SET @rol = 'REFUGIO';
    END
    ELSE
    BEGIN

        SELECT TOP 1
            @id_veterinaria = pv.id_veterinaria
        FROM dbo.profesionales_veterinarias pv
        WHERE pv.id_profesional = @id_ciudadano
          AND pv.baja = 'N'
        ORDER BY pv.id_veterinaria;

        IF @id_veterinaria IS NOT NULL
            SET @rol = 'PROFESIONAL';
        ELSE
            SET @rol = 'CIUDADANO';

    END;

    SELECT
        idCiudadano   = dbo.fn_cifrar_id(@id_ciudadano),
        idRefugio     = dbo.fn_cifrar_id(@id_refugio),      -- NULL si no tiene
        idVeterinaria = dbo.fn_cifrar_id(@id_veterinaria),  -- NULL si no tiene

        razonSocial =
            CASE
                WHEN @rol = 'REFUGIO'
                    THEN (SELECT razon_social
                          FROM dbo.refugios
                          WHERE id_refugio = @id_refugio)

                WHEN @rol = 'PROFESIONAL'
                    THEN (SELECT razon_social
                          FROM dbo.veterinarias
                          WHERE id_veterinaria = @id_veterinaria)

                ELSE NULL
            END,

        rol = @rol;

END;
GO

-- execute dbo.aut_usuario @cuil='27456789012', @clave='clave300001'   -- REFUGIO
-- execute dbo.aut_usuario @cuil='20178901234', @clave='clave200001'   -- PROFESIONAL
-- execute dbo.aut_usuario @cuil='20123456789', @clave='clave100001'   -- CIUDADANO
-- execute dbo.aut_usuario @cuil='27456789012', @clave='incorrecta'    -- resultset vacio