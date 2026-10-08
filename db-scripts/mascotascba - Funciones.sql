USE mascotascba;
GO


CREATE OR ALTER FUNCTION dbo.fn_cifrar_id
(
    @id INT
)
RETURNS VARCHAR(1024)
AS
BEGIN
    RETURN CONVERT(
        VARCHAR(1024),
        ENCRYPTBYPASSPHRASE(
            CONVERT(VARCHAR(20), @id),
            CONVERT(VARCHAR(20), @id)
        ),
        2
    );
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_id_coincide
(
    @id_cifrado VARCHAR(1024),
    @id         INT
)
RETURNS BIT
AS
BEGIN
    RETURN CASE
        WHEN TRY_CONVERT(
                 INT,
                 CONVERT(
                     VARCHAR(20),
                     DECRYPTBYPASSPHRASE(
                         CONVERT(VARCHAR(20), @id),
                         TRY_CONVERT(VARBINARY(1024), @id_cifrado, 2)
                     )
                 )
             ) = @id
        THEN 1 ELSE 0
    END;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_ciudadano_autorizado
(
    @id_ciudadano VARCHAR(1024)
)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT TOP 1 c.id_ciudadano
        FROM dbo.ciudadanos c
        WHERE c.habilitado = 'S'
          AND dbo.fn_id_coincide(@id_ciudadano, c.id_ciudadano) = 1
    );
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_refugio_autorizado
(
    @id_ciudadano VARCHAR(1024),
    @id_refugio   VARCHAR(1024)
)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT TOP 1 r.id_refugio
        FROM dbo.refugios r
        INNER JOIN dbo.ciudadanos c
            ON  c.id_ciudadano = r.id_responsable
            AND c.habilitado   = 'S'
        WHERE dbo.fn_id_coincide(@id_refugio,   r.id_refugio)   = 1
          AND dbo.fn_id_coincide(@id_ciudadano, c.id_ciudadano) = 1
    );
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_veterinaria_autorizada
(
    @id_ciudadano   VARCHAR(1024),
    @id_veterinaria VARCHAR(1024)
)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT TOP 1 pv.id_veterinaria
        FROM dbo.profesionales_veterinarias pv
        INNER JOIN dbo.ciudadanos c
            ON  c.id_ciudadano = pv.id_profesional
            AND c.habilitado   = 'S'
        WHERE pv.baja = 'N'
          AND dbo.fn_id_coincide(@id_veterinaria, pv.id_veterinaria) = 1
          AND dbo.fn_id_coincide(@id_ciudadano,   c.id_ciudadano)    = 1
    );
END;
GO

