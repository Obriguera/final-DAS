USE mascotascba;
GO

/* ---------- Catalogos ---------- */

CREATE OR ALTER PROCEDURE dbo.get_especies
AS
BEGIN
    SET NOCOUNT ON;

    SELECT nom_valor_dominio
    FROM dbo.dominio_rasgos_mascotas
    WHERE cod_rasgo = 6
    ORDER BY nro_valor_dominio;
END;
GO

-- exec dbo.get_especies;


CREATE OR ALTER PROCEDURE dbo.get_razas
AS
BEGIN
    SET NOCOUNT ON;

    SELECT nom_valor_dominio
    FROM dbo.dominio_rasgos_mascotas
    WHERE cod_rasgo = 4
    ORDER BY nom_valor_dominio;
END;
GO

-- exec dbo.get_razas;

/* ---------- Listado de publicaciones del refugio ---------- */

CREATE OR ALTER PROCEDURE dbo.get_publicaciones
(
    @id_refugio INT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.nro_publicacion,
        p.nro_reg_municipal,
        m.nombre,
        esp.nom_valor_dominio AS especie,
        raz.nom_valor_dominio AS raza,
        m.sexo,
        m.anio_nacimiento,
        p.caracteristicas_mascota,
        p.condicion_adopcion,
        p.foto,
        p.estado_publicacion,
        p.fecha_publicacion
    FROM dbo.publicaciones_adopcion p

    INNER JOIN dbo.mascotas m
        ON m.nro_reg_municipal = p.nro_reg_municipal

    LEFT JOIN dbo.caracteristicas_mascotas ce
        ON ce.nro_reg_municipal = m.nro_reg_municipal
        AND ce.cod_rasgo = 6
        AND ce.nro_caracteristica = 1

    LEFT JOIN dbo.dominio_rasgos_mascotas esp
        ON esp.cod_rasgo = ce.cod_rasgo
        AND esp.nro_valor_dominio = ce.nro_valor_dominio

    LEFT JOIN dbo.caracteristicas_mascotas cr
        ON cr.nro_reg_municipal = m.nro_reg_municipal
        AND cr.cod_rasgo = 4
        AND cr.nro_caracteristica = 1

    LEFT JOIN dbo.dominio_rasgos_mascotas raz
        ON raz.cod_rasgo = cr.cod_rasgo
        AND raz.nro_valor_dominio = cr.nro_valor_dominio

    WHERE p.id_refugio = @id_refugio

    ORDER BY
        p.fecha_publicacion DESC,
        p.nro_publicacion DESC;
END;
GO


-- exec dbo.get_publicaciones @id_refugio = 500001;


/* ---------- Crear publicación ---------- */

CREATE OR ALTER PROCEDURE dbo.crear_publicacion
(
    @id_refugio              INT,
    @nombre                  VARCHAR(100),
    @sexo                    CHAR(1),
    @anio_nacimiento         INT = NULL,
    @especie                 VARCHAR(100),
    @raza                    VARCHAR(100) = NULL,
    @caracteristicas_mascota VARCHAR(500),
    @condicion_adopcion      VARCHAR(300),
    @foto                    VARCHAR(300)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @numero_mascota INT;
    DECLARE @nro_reg_municipal VARCHAR(30);
    DECLARE @nro_publicacion INT;
    DECLARE @id_especie INT;
    DECLARE @id_raza INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Buscar el código de especie */
        SELECT @id_especie = nro_valor_dominio
        FROM dbo.dominio_rasgos_mascotas
        WHERE cod_rasgo = 6
          AND nom_valor_dominio = @especie;

        /* Buscar el código de raza, si fue informada */
        IF @raza IS NOT NULL
        BEGIN
            SELECT @id_raza = nro_valor_dominio
            FROM dbo.dominio_rasgos_mascotas
            WHERE cod_rasgo = 4
              AND nom_valor_dominio = @raza;
        END;

        /* Generar el Número de Registro Municipal */
        SELECT @numero_mascota =
            ISNULL(
                MAX(
                    TRY_CONVERT(
                        INT,
                        REPLACE(nro_reg_municipal, 'MUN-', '')
                    )
                ),
                0
            ) + 1
        FROM dbo.mascotas WITH (UPDLOCK, HOLDLOCK);

        SET @nro_reg_municipal =
            'MUN-' +
            RIGHT(
                '000000' + CAST(@numero_mascota AS VARCHAR(6)),
                6
            );

        /* Generar el número de publicación */
        SELECT @nro_publicacion =
            ISNULL(MAX(nro_publicacion), 600000) + 1
        FROM dbo.publicaciones_adopcion
            WITH (UPDLOCK, HOLDLOCK);

        /* Crear mascota */
        INSERT INTO dbo.mascotas
        (
            nro_reg_municipal,
            nombre,
            sexo,
            anio_nacimiento,
            microchip,
            vive,
            id_responsable,
            id_refugio
        )
        VALUES
        (
            @nro_reg_municipal,
            @nombre,
            @sexo,
            @anio_nacimiento,
            NULL,
            'S',
            NULL,
            @id_refugio
        );

        /* Registrar especie */
        INSERT INTO dbo.caracteristicas_mascotas
        (
            nro_reg_municipal,
            cod_rasgo,
            nro_caracteristica,
            nro_valor_dominio,
            valor_caracteristica
        )
        VALUES
        (
            @nro_reg_municipal,
            6,
            1,
            @id_especie,
            NULL
        );

        /* Registrar raza, si fue informada */
        IF @id_raza IS NOT NULL
        BEGIN
            INSERT INTO dbo.caracteristicas_mascotas
            (
                nro_reg_municipal,
                cod_rasgo,
                nro_caracteristica,
                nro_valor_dominio,
                valor_caracteristica
            )
            VALUES
            (
                @nro_reg_municipal,
                4,
                1,
                @id_raza,
                NULL
            );
        END;

        /* Crear publicación */
        INSERT INTO dbo.publicaciones_adopcion
        (
            nro_publicacion,
            nro_reg_municipal,
            id_refugio,
            fecha_publicacion,
            caracteristicas_mascota,
            condicion_adopcion,
            foto,
            estado_publicacion
        )
        VALUES
        (
            @nro_publicacion,
            @nro_reg_municipal,
            @id_refugio,
            CAST(GETDATE() AS DATE),
            @caracteristicas_mascota,
            @condicion_adopcion,
            @foto,
            'ACTIVA'
        );

        COMMIT TRANSACTION;

        /* Respuesta para la API */
        SELECT
            @nro_publicacion AS nroPublicacion,
            @nro_reg_municipal AS nroRegMunicipal,
            'ACTIVA' AS estadoPublicacion;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

/*
exec dbo.crear_publicacion
    @id_refugio = 500001,
    @nombre = 'Manchita',
    @sexo = 'H',
    @anio_nacimiento = 2024,
    @especie = 'Perro',
    @raza = 'Mestizo',
    @caracteristicas_mascota = 'Carinosa y tranquila.',
    @condicion_adopcion = 'Entrevista previa.',
    @foto = 'manchita.jpg';
GO
*/

/*
exec dbo.get_publicaciones
    @id_refugio = 500001;
*/

/* ---------- Consultar estado ---------- */

CREATE OR ALTER PROCEDURE dbo.get_estado_publicacion
(
    @nro_publicacion INT,
    @id_refugio INT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT estado_publicacion
    FROM dbo.publicaciones_adopcion
    WHERE nro_publicacion = @nro_publicacion
      AND id_refugio = @id_refugio;
END;
GO
/*
exec dbo.get_estado_publicacion
    @nro_publicacion = 600001,
    @id_refugio = 500001;
*/

/* ---------- Actualizar estado ---------- */

CREATE OR ALTER PROCEDURE dbo.act_estado_publicacion
(
    @nro_publicacion INT,
    @id_refugio INT,
    @estado_actual VARCHAR(30),
    @estado_nuevo VARCHAR(30)
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.publicaciones_adopcion
    SET estado_publicacion = @estado_nuevo
    WHERE nro_publicacion = @nro_publicacion
      AND id_refugio = @id_refugio
      AND estado_publicacion = @estado_actual;

    SELECT @@ROWCOUNT AS filas;
END;
GO


/*
exec dbo.act_estado_publicacion
    @nro_publicacion = 600001,
    @id_refugio = 500001,
    @estado_actual = 'ACTIVA',
    @estado_nuevo = 'PAUSADA';
*/