USE mascotascba;
GO


CREATE OR ALTER PROCEDURE dbo.get_publicaciones
(
    @id_ciudadano VARCHAR(1024),
    @id_refugio VARCHAR(1024),
    @nombre     VARCHAR(100) = NULL,
    @estado     VARCHAR(30)  = NULL
)
AS
BEGIN

    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@nombre, ''))) = ''
        SET @nombre = NULL;

    IF LTRIM(RTRIM(ISNULL(@estado, ''))) = ''
        SET @estado = NULL;
    ELSE
        SET @estado = UPPER(LTRIM(RTRIM(@estado)));

    DECLARE @id_refugio_int INT =
        dbo.fn_refugio_autorizado(@id_ciudadano, @id_refugio);

    IF @id_refugio_int IS NULL
    BEGIN

        SELECT
            nroPublicacion         = NULL,
            nroRegMunicipal        = NULL,
            nombre                 = NULL,
            especie                = NULL,
            sexo                   = NULL,
            edad                   = NULL,
            caracteristicasMascota = NULL,
            condicionAdopcion      = NULL,
            foto                   = NULL,
            estadoPublicacion      = NULL,
            fechaPublicacion       = NULL
        WHERE 1 = 0;

        RETURN;

    END;

    SELECT

        nroPublicacion =
            CONVERT(
                VARCHAR(1024),
                ENCRYPTBYPASSPHRASE(
                    CONVERT(VARCHAR(20), p.nro_publicacion),
                    CONVERT(VARCHAR(20), p.nro_publicacion)
                ),
                2
            ),

        nroRegMunicipal        = m.nro_reg_municipal,
        nombre                 = m.nombre,
        especie                = esp.nom_valor_dominio,   -- Perro / Gato / Otro
        sexo                   = m.sexo,                  -- 'H' / 'M'

        edad =                                            -- en anios, NULL si no se conoce
            CASE
                WHEN m.[año_nacimiento] IS NULL THEN NULL
                ELSE YEAR(GETDATE()) - m.[año_nacimiento]
            END,

        caracteristicasMascota = p.caracteristicas_mascota,
        condicionAdopcion      = p.condicion_adopcion,
        foto                   = p.foto,
        estadoPublicacion      = p.estado_publicacion,
        fechaPublicacion       = p.fecha_publicacion

    FROM dbo.publicaciones_adopcion p

    INNER JOIN dbo.mascotas m
        ON m.nro_reg_municipal = p.nro_reg_municipal

    OUTER APPLY (
        SELECT TOP 1 d.nom_valor_dominio
        FROM dbo.caracteristicas_mascotas cm
        INNER JOIN dbo.dominio_rasgos_mascotas d
            ON  d.cod_rasgo         = cm.cod_rasgo
            AND d.nro_valor_dominio = cm.nro_valor_dominio
        WHERE cm.nro_reg_municipal = m.nro_reg_municipal
          AND cm.cod_rasgo = 6                              -- Especie
        ORDER BY cm.nro_caracteristica
    ) esp

    WHERE p.id_refugio = @id_refugio_int

      AND (
            @nombre IS NULL
            OR m.nombre LIKE '%' + @nombre + '%'
          )

      AND (
            @estado IS NULL
            OR p.estado_publicacion = @estado
          )

    ORDER BY p.fecha_publicacion DESC, p.nro_publicacion DESC;

END;
GO

-- execute dbo.get_publicaciones @id_ciudadano='020000009001981311EE75A8B36FE341B328D745560C84F3E3E45FD9CFACB98EF48857D1', @id_refugio='020000001D455E90C806D46C647B7B69BA92D7FBE9EF406B2D43E62F95DC2F007F47B998', @estado=NULL, @nombre=NULL



CREATE OR ALTER PROCEDURE dbo.crear_publicacion
(
    @id_ciudadano VARCHAR(1024),
    @id_refugio              VARCHAR(1024),
    @nombre                  VARCHAR(200),
    @especie                 VARCHAR(100),            -- Perro / Gato / Otro
    @sexo                    VARCHAR(20),             -- Hembra / Macho (o H / M)
    @edad_aproximada         VARCHAR(50)   = NULL,    -- "2", "2 años", "6 meses"
    @raza                    VARCHAR(200)  = NULL,    -- texto libre
    @caracteristicas_mascota VARCHAR(1000),           -- descripcion general
    @condicion_adopcion      VARCHAR(1000),
    @foto                    VARCHAR(500)
)
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @id_refugio_int INT =
        dbo.fn_refugio_autorizado(@id_ciudadano, @id_refugio);
    DECLARE @valor_especie INT;
    DECLARE @valor_raza INT;
    DECLARE @anio_nacimiento INT = NULL;
    DECLARE @nro_reg_municipal VARCHAR(30);
    DECLARE @nro_publicacion INT;
    DECLARE @n INT;

    SET @nombre                  = LTRIM(RTRIM(ISNULL(@nombre, '')));
    SET @especie                 = LTRIM(RTRIM(ISNULL(@especie, '')));
    SET @sexo                    = UPPER(LEFT(LTRIM(RTRIM(ISNULL(@sexo, ''))), 1));
    SET @edad_aproximada         = LTRIM(RTRIM(ISNULL(@edad_aproximada, '')));
    SET @raza                    = NULLIF(LTRIM(RTRIM(ISNULL(@raza, ''))), '');
    SET @caracteristicas_mascota = LTRIM(RTRIM(ISNULL(@caracteristicas_mascota, '')));
    SET @condicion_adopcion      = LTRIM(RTRIM(ISNULL(@condicion_adopcion, '')));
    SET @foto                    = LTRIM(RTRIM(ISNULL(@foto, '')));

    /* ---------- Validaciones ---------- */

    IF @nombre = '' OR LEN(@nombre) > 100
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'DATOS_INVALIDOS',
               mensaje = 'El nombre es obligatorio (maximo 100 caracteres)';
        RETURN;
    END;

    IF @sexo NOT IN ('H', 'M')
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'DATOS_INVALIDOS',
               mensaje = 'El sexo debe ser Hembra o Macho';
        RETURN;
    END;

    IF @caracteristicas_mascota = '' OR LEN(@caracteristicas_mascota) > 500
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'DATOS_INVALIDOS',
               mensaje = 'La descripcion es obligatoria (maximo 500 caracteres)';
        RETURN;
    END;

    IF @condicion_adopcion = '' OR LEN(@condicion_adopcion) > 300
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'DATOS_INVALIDOS',
               mensaje = 'Las condiciones de adopcion son obligatorias (maximo 300 caracteres)';
        RETURN;
    END;

    IF @foto = '' OR LEN(@foto) > 300
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'DATOS_INVALIDOS',
               mensaje = 'La fotografia es obligatoria';
        RETURN;
    END;

    IF @raza IS NOT NULL AND LEN(@raza) > 200
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'DATOS_INVALIDOS',
               mensaje = 'La raza es demasiado larga';
        RETURN;
    END;

    -- Edad aproximada -> anio de nacimiento
    IF @edad_aproximada <> ''
    BEGIN
        DECLARE @pos INT = PATINDEX('%[^0-9]%', @edad_aproximada + 'x');
        DECLARE @edad INT = CASE WHEN @pos > 1
                                 THEN TRY_CONVERT(INT, LEFT(@edad_aproximada, @pos - 1))
                            END;

        IF @edad IS NULL OR @edad > 40 * 12
        BEGIN
            SELECT resultado = 'ERROR', codigo = 'DATOS_INVALIDOS',
                   mensaje = 'La edad aproximada no es valida (ej: 2 años)';
            RETURN;
        END;

        IF @edad_aproximada LIKE '%mes%'
            SET @edad = @edad / 12;

        IF @edad > 40
        BEGIN
            SELECT resultado = 'ERROR', codigo = 'DATOS_INVALIDOS',
                   mensaje = 'La edad aproximada no es valida (ej: 2 años)';
            RETURN;
        END;

        SET @anio_nacimiento = YEAR(GETDATE()) - @edad;
    END;

    -- Refugio
    IF @id_refugio_int IS NULL
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'NO_AUTORIZADO',
               mensaje = 'El usuario no esta autorizado para operar sobre el refugio';
        RETURN;
    END;

    -- Especie 
    SELECT TOP 1
        @valor_especie = d.nro_valor_dominio
    FROM dbo.dominio_rasgos_mascotas d
    WHERE d.cod_rasgo = 6
      AND d.nom_valor_dominio = @especie;

    IF @valor_especie IS NULL
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'DATOS_INVALIDOS',
               mensaje = 'Especie invalida';
        RETURN;
    END;

    -- Raza: si coincide con el dominio se guarda el valor,
    -- si no, se guarda el texto libre en valor_caracteristica
    IF @raza IS NOT NULL
    BEGIN
        SELECT TOP 1
            @valor_raza = d.nro_valor_dominio
        FROM dbo.dominio_rasgos_mascotas d
        WHERE d.cod_rasgo = 4
          AND d.nom_valor_dominio = @raza;
    END;

    /* ---------- Alta ---------- */

    BEGIN TRANSACTION;

        -- nro_reg_municipal: MUN-000001, MUN-000002, ...
        SELECT
            @n = ISNULL(MAX(TRY_CONVERT(INT, SUBSTRING(m.nro_reg_municipal, 5, 26))), 0) + 1
        FROM dbo.mascotas m WITH (UPDLOCK, HOLDLOCK)
        WHERE m.nro_reg_municipal LIKE 'MUN-%';

        SET @nro_reg_municipal = 'MUN-' + FORMAT(@n, '000000');

        SELECT
            @nro_publicacion = ISNULL(MAX(p.nro_publicacion), 0) + 1
        FROM dbo.publicaciones_adopcion p WITH (UPDLOCK, HOLDLOCK);

        INSERT INTO dbo.mascotas
            (nro_reg_municipal, nombre, sexo, [año_nacimiento], microchip, vive, id_responsable, id_refugio)
        VALUES
            (@nro_reg_municipal, @nombre, @sexo, @anio_nacimiento, NULL, 'S', NULL, @id_refugio_int);

        INSERT INTO dbo.caracteristicas_mascotas
            (nro_reg_municipal, cod_rasgo, nro_caracteristica, nro_valor_dominio, valor_caracteristica)
        VALUES
            (@nro_reg_municipal, 6, 1, @valor_especie, NULL);

        IF @raza IS NOT NULL
        BEGIN
            INSERT INTO dbo.caracteristicas_mascotas
                (nro_reg_municipal, cod_rasgo, nro_caracteristica, nro_valor_dominio, valor_caracteristica)
            VALUES
                (@nro_reg_municipal, 4, 1, @valor_raza,
                 CASE WHEN @valor_raza IS NULL THEN @raza END);
        END;

        INSERT INTO dbo.publicaciones_adopcion
            (nro_publicacion, nro_reg_municipal, id_refugio, fecha_publicacion,
             caracteristicas_mascota, condicion_adopcion, foto, estado_publicacion)
        VALUES
            (@nro_publicacion, @nro_reg_municipal, @id_refugio_int, CAST(GETDATE() AS DATE),
             @caracteristicas_mascota, @condicion_adopcion, @foto, 'ACTIVA');

    COMMIT TRANSACTION;

    SELECT
        resultado         = 'OK',
        nroPublicacion    =
            CONVERT(
                VARCHAR(1024),
                ENCRYPTBYPASSPHRASE(
                    CONVERT(VARCHAR(20), @nro_publicacion),
                    CONVERT(VARCHAR(20), @nro_publicacion)
                ),
                2
            ),
        nroRegMunicipal   = @nro_reg_municipal,
        estadoPublicacion = 'ACTIVA';

END;
GO

-- execute dbo.crear_publicacion
--    @id_ciudadano='020000009001981311EE75A8B36FE341B328D745560C84F3E3E45FD9CFACB98EF48857D1', @id_refugio='020000001D455E90C806D46C647B7B69BA92D7FBE9EF406B2D43E62F95DC2F007F47B998',
--     @nombre='Manchita', @especie='Perro', @sexo='Hembra', @edad_aproximada='2 años',
--     @raza='Mestizo', @caracteristicas_mascota='Cariñosa y tranquila.',
--     @condicion_adopcion='Entrevista previa y compromiso de tenencia responsable.',
--     @foto='manchita.jpg'



CREATE OR ALTER PROCEDURE dbo.act_estado_publicacion
(
    @nro_publicacion VARCHAR(1024),
    @id_ciudadano VARCHAR(1024),
    @id_refugio      VARCHAR(1024),
    @accion          VARCHAR(20)
)
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @nro_publicacion_binary VARBINARY(MAX) =
        TRY_CONVERT(VARBINARY(MAX), @nro_publicacion, 2);

    DECLARE @nro_publicacion_int INT;
    DECLARE @id_refugio_int INT =
        dbo.fn_refugio_autorizado(@id_ciudadano, @id_refugio);
    DECLARE @estado_actual VARCHAR(30);
    DECLARE @nuevo_estado VARCHAR(30);

    SET @accion = UPPER(LTRIM(RTRIM(ISNULL(@accion, ''))));

    -- Refugio
    IF @id_refugio_int IS NULL
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'NO_AUTORIZADO',
               mensaje = 'El usuario no esta autorizado para operar sobre el refugio';
        RETURN;
    END;

    -- Publicacion 
    SELECT TOP 1
        @nro_publicacion_int = p.nro_publicacion,
        @estado_actual       = p.estado_publicacion
    FROM dbo.publicaciones_adopcion p
    WHERE p.id_refugio = @id_refugio_int
      AND TRY_CONVERT(
              INT,
              CONVERT(
                  VARCHAR(20),
                  DECRYPTBYPASSPHRASE(
                      CONVERT(VARCHAR(20), p.nro_publicacion),
                      @nro_publicacion_binary
                  )
              )
          ) = p.nro_publicacion;

    IF @nro_publicacion_int IS NULL
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'NO_ENCONTRADO',
               mensaje = 'La publicacion no existe o no pertenece al refugio';
        RETURN;
    END;

    -- Transiciones permitidas
    SET @nuevo_estado =
        CASE
            WHEN @estado_actual = 'ACTIVA'  AND @accion = 'PAUSAR'    THEN 'PAUSADA'
            WHEN @estado_actual = 'ACTIVA'  AND @accion = 'FINALIZAR' THEN 'FINALIZADA'
            WHEN @estado_actual = 'PAUSADA' AND @accion = 'ACTIVAR'   THEN 'ACTIVA'
            WHEN @estado_actual = 'PAUSADA' AND @accion = 'FINALIZAR' THEN 'FINALIZADA'
            ELSE NULL
        END;

    IF @nuevo_estado IS NULL
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'ESTADO_INVALIDO',
               mensaje = 'Accion no permitida para el estado actual';
        RETURN;
    END;

    UPDATE dbo.publicaciones_adopcion
    SET estado_publicacion = @nuevo_estado
    WHERE nro_publicacion = @nro_publicacion_int
      AND estado_publicacion = @estado_actual;

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'ESTADO_INVALIDO',
               mensaje = 'La publicacion cambio de estado, actualice el listado';
        RETURN;
    END;

    SELECT
        resultado         = 'OK',
        estadoPublicacion = @nuevo_estado;

END;
GO

-- execute dbo.act_estado_publicacion @id_ciudadano='020000009001981311EE75A8B36FE341B328D745560C84F3E3E45FD9CFACB98EF48857D1', @id_refugio='020000001D455E90C806D46C647B7B69BA92D7FBE9EF406B2D43E62F95DC2F007F47B998', @nro_publicacion='02000000077E4E3B43EE05A71FC9715E5402C28686A6104BAB169198C861816D31F2FAA8', @accion='Finalizar'