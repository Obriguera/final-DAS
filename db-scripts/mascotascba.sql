USE mascotascba;
GO

DROP TABLE IF EXISTS dbo.configuracion_veterinarias;
DROP TABLE IF EXISTS dbo.informacion_sanitaria;
DROP TABLE IF EXISTS dbo.publicaciones_adopcion;
DROP TABLE IF EXISTS dbo.caracteristicas_mascotas;
DROP TABLE IF EXISTS dbo.profesionales_veterinarias;
DROP TABLE IF EXISTS dbo.mascotas;
DROP TABLE IF EXISTS dbo.dominio_rasgos_mascotas;
DROP TABLE IF EXISTS dbo.tipos_atencion_sanitaria;
DROP TABLE IF EXISTS dbo.atributos_sistema;
DROP TABLE IF EXISTS dbo.rasgos_mascotas;
DROP TABLE IF EXISTS dbo.refugios;
DROP TABLE IF EXISTS dbo.veterinarias;
DROP TABLE IF EXISTS dbo.ciudadanos;
GO


/* ----------------         TABLAS            ---------------------*/


CREATE TABLE ciudadanos (
    id_ciudadano    INT             NOT NULL,
    apellido        VARCHAR(100)    NOT NULL,
    nombre          VARCHAR(100)    NOT NULL,
    cuil            VARCHAR(20)     NOT NULL,
    clave           VARCHAR(200),
    correo          VARCHAR(150),
    telefono        VARCHAR(30),
    domicilio       VARCHAR(200),
    habilitado      CHAR(1)         DEFAULT 'S',

    CONSTRAINT pk_ciudadanos
        PRIMARY KEY (id_ciudadano),

    CONSTRAINT uq_ciudadanos_cuil
        UNIQUE (cuil)
);
GO


CREATE TABLE veterinarias (
    id_veterinaria          INT             NOT NULL,
    razon_social            VARCHAR(150)    NOT NULL,
    correo                  VARCHAR(150),
    telefono                VARCHAR(30),
    domicilio               VARCHAR(200),
    habilitacion_municipal  VARCHAR(50),

    CONSTRAINT pk_veterinarias
        PRIMARY KEY (id_veterinaria)
);
GO


CREATE TABLE refugios (
    id_refugio              INT             NOT NULL,
    razon_social            VARCHAR(150)    NOT NULL,
    correo                  VARCHAR(150),
    telefono                VARCHAR(30),
    domicilio               VARCHAR(200),
    habilitacion_municipal  VARCHAR(50),
    id_responsable          INT             NOT NULL,

    CONSTRAINT pk_refugios
        PRIMARY KEY (id_refugio),

    CONSTRAINT fk_refugios_ciudadanos
        FOREIGN KEY (id_responsable)
        REFERENCES ciudadanos (id_ciudadano)
);
GO



CREATE TABLE rasgos_mascotas (
    cod_rasgo   INT             NOT NULL,
    nom_rasgo   VARCHAR(100)    NOT NULL,

    CONSTRAINT pk_rasgos_mascotas
        PRIMARY KEY (cod_rasgo)
);
GO


CREATE TABLE dominio_rasgos_mascotas (
    cod_rasgo            INT             NOT NULL,
    nro_valor_dominio    INT             NOT NULL,
    nom_valor_dominio    VARCHAR(100)    NOT NULL,

    CONSTRAINT pk_dominio_rasgos_mascotas
        PRIMARY KEY (cod_rasgo, nro_valor_dominio),

    CONSTRAINT fk_dominiorasgos_rasgos
        FOREIGN KEY (cod_rasgo)
        REFERENCES rasgos_mascotas (cod_rasgo)
);
GO


CREATE TABLE mascotas (
    nro_reg_municipal   VARCHAR(30)     NOT NULL,
    nombre              VARCHAR(100)    NOT NULL,
    sexo                CHAR(1),
    año_nacimiento      INT,
    microchip           VARCHAR(50),
    vive                CHAR(1)         DEFAULT 'S',
    id_responsable      INT,
    id_refugio          INT,

    CONSTRAINT pk_mascotas
        PRIMARY KEY (nro_reg_municipal),

    CONSTRAINT fk_mascotas_ciudadanos
        FOREIGN KEY (id_responsable)
        REFERENCES ciudadanos (id_ciudadano),

    CONSTRAINT fk_mascotas_refugios
        FOREIGN KEY (id_refugio)
        REFERENCES refugios (id_refugio)
);
GO


CREATE TABLE caracteristicas_mascotas (
    nro_reg_municipal     VARCHAR(30)     NOT NULL,
    cod_rasgo             INT             NOT NULL,
    nro_caracteristica    INT             NOT NULL,
    nro_valor_dominio     INT,
    valor_caracteristica  VARCHAR(200),

    CONSTRAINT pk_caracteristicas_mascotas
        PRIMARY KEY (
            nro_reg_municipal,
            cod_rasgo,
            nro_caracteristica
        ),

    CONSTRAINT fk_caracmasc_mascotas
        FOREIGN KEY (nro_reg_municipal)
        REFERENCES mascotas (nro_reg_municipal),

    CONSTRAINT fk_caracmasc_rasgos
        FOREIGN KEY (cod_rasgo)
        REFERENCES rasgos_mascotas (cod_rasgo),

    CONSTRAINT fk_caracmasc_dominio
        FOREIGN KEY (cod_rasgo, nro_valor_dominio)
        REFERENCES dominio_rasgos_mascotas
            (cod_rasgo, nro_valor_dominio)
);
GO


CREATE TABLE profesionales_veterinarias (
    id_veterinaria  INT         NOT NULL,
    id_profesional  INT         NOT NULL,
    baja            CHAR(1)     DEFAULT 'N',

    CONSTRAINT pk_profesionales_veterinarias
        PRIMARY KEY (
            id_veterinaria,
            id_profesional
        ),

    CONSTRAINT fk_profvet_veterinarias
        FOREIGN KEY (id_veterinaria)
        REFERENCES veterinarias (id_veterinaria),

    CONSTRAINT fk_profvet_ciudadanos
        FOREIGN KEY (id_profesional)
        REFERENCES ciudadanos (id_ciudadano)
);
GO


CREATE TABLE publicaciones_adopcion (
    nro_publicacion          INT             NOT NULL,
    nro_reg_municipal       VARCHAR(30)     NOT NULL,
    id_refugio               INT,
    fecha_publicacion        DATE            NOT NULL,
    caracteristicas_mascota VARCHAR(500),
    condicion_adopcion      VARCHAR(300),
    foto                     VARCHAR(300),
    estado_publicacion      VARCHAR(30),

    CONSTRAINT pk_publicaciones_adopcion
        PRIMARY KEY (nro_publicacion),

    CONSTRAINT fk_publadop_mascotas
        FOREIGN KEY (nro_reg_municipal)
        REFERENCES mascotas (nro_reg_municipal),

    CONSTRAINT fk_publadop_refugios
        FOREIGN KEY (id_refugio)
        REFERENCES refugios (id_refugio)
);
GO


CREATE TABLE tipos_atencion_sanitaria (
    cod_tipo_atencion   INT             NOT NULL,
    desc_tipo_atencion  VARCHAR(100)    NOT NULL,

    CONSTRAINT pk_tipos_atencion_sanitaria
        PRIMARY KEY (cod_tipo_atencion)
);
GO


CREATE TABLE informacion_sanitaria (
    nro_reg_municipal   VARCHAR(30)     NOT NULL,
    nro_registro        INT             NOT NULL,
    fecha_atencion      DATE            NOT NULL,
    cod_tipo_atencion   INT             NOT NULL,
    detalle_atencion    VARCHAR(500),
    fecha_vencimiento   DATE,
    id_veterinaria      INT,
    id_profesional      INT,

    CONSTRAINT pk_informacion_sanitaria
        PRIMARY KEY (
            nro_reg_municipal,
            nro_registro
        ),

    CONSTRAINT fk_infosan_mascotas
        FOREIGN KEY (nro_reg_municipal)
        REFERENCES mascotas (nro_reg_municipal),

    CONSTRAINT fk_infosan_tipos
        FOREIGN KEY (cod_tipo_atencion)
        REFERENCES tipos_atencion_sanitaria (cod_tipo_atencion),

    CONSTRAINT fk_infosan_veterinarias
        FOREIGN KEY (id_veterinaria)
        REFERENCES veterinarias (id_veterinaria),

    CONSTRAINT fk_infosan_profesionales
        FOREIGN KEY (id_profesional)
        REFERENCES ciudadanos (id_ciudadano),

    CONSTRAINT fk_infosan_profvet
        FOREIGN KEY (id_veterinaria, id_profesional)
        REFERENCES profesionales_veterinarias
            (id_veterinaria, id_profesional)
);
GO


CREATE TABLE atributos_sistema (
    cod_atributo     INT             NOT NULL,
    desc_atributo    VARCHAR(100)    NOT NULL,
    tipo_dato        VARCHAR(30),
    observ_atributo  VARCHAR(300),

    CONSTRAINT pk_atributos_sistema
        PRIMARY KEY (cod_atributo)
);
GO

CREATE TABLE configuracion_veterinarias (
    id_veterinaria  INT             NOT NULL,
    cod_atributo    INT             NOT NULL,
    valor           VARCHAR(200),

    CONSTRAINT pk_configuracion_veterinarias
        PRIMARY KEY (
            id_veterinaria,
            cod_atributo
        ),

    CONSTRAINT fk_confvet_veterinarias
        FOREIGN KEY (id_veterinaria)
        REFERENCES veterinarias (id_veterinaria),

    CONSTRAINT fk_confvet_atributos
        FOREIGN KEY (cod_atributo)
        REFERENCES atributos_sistema (cod_atributo)
);
GO



/* ----------------         DATOS            ---------------------*/



INSERT INTO dbo.ciudadanos
    (id_ciudadano, apellido, nombre, cuil, clave, correo, telefono, domicilio, habilitado)
VALUES
    (100001, 'Perez', 'Juan', '20123456789', 'clave100001', 'juan.perez@gmail.com', '3515551001', 'Av. Colon 1000', 'S'),
    (100002, 'Gomez', 'Maria', '27234567890', 'clave100002', 'maria.gomez@gmail.com', '3515551002', 'Dean Funes 1200', 'S'),
    (100003, 'Rodriguez', 'Carlos', '20345678901', 'clave100003', 'carlos.rodriguez@gmail.com', '3515551003', 'La Rioja 800', 'S'),
    (200001, 'Sanchez', 'Pedro', '20178901234', 'clave200001', 'pedro.sanchez@gmail.com', '3515552001', 'Obispo Trejo 700', 'S'),
    (200002, 'Lopez', 'Ana', '27289012345', 'clave200002', 'ana.lopez@gmail.com', '3515552002', 'Chacabuco 600', 'S'),
    (200003, 'Gonzalez', 'Diego', '20390123456', 'clave200003', 'diego.gonzalez@gmail.com', '3515552003', 'Maipu 500', 'S'),
    (200004, 'Diaz', 'Lucia', '27401234567', 'clave200004', 'lucia.diaz@gmail.com', '3515552004', 'Ituzaingo 1100', 'S'),
    (300001, 'Fernandez', 'Laura', '27456789012', 'clave300001', 'laura.fernandez@gmail.com', '3515553001', 'Santa Rosa 1500', 'S'),
    (300002, 'Martinez', 'Sofia', '27567890123', 'clave300002', 'sofia.martinez@gmail.com', '3515553002', 'Ituzaingo 900', 'S');
GO

INSERT INTO dbo.veterinarias
    (id_veterinaria, razon_social, correo, telefono, domicilio, habilitacion_municipal)
VALUES
    (400001, 'Veterinaria Cordoba SRL', 'contacto@veterinariacordoba.com', '3514441001', 'Av. Rafael Nunez 3000', 'HAB-400001'),
    (400002, 'Centro Veterinario Alberdi', 'contacto@vetalberdi.com', '3514441002', 'Av. Colon 2500', 'HAB-400002'),
    (400003, 'Veterinaria Nueva Cordoba', 'contacto@vetnuevacordoba.com', '3514441003', 'Hipolito Yrigoyen 800', 'HAB-400003');
GO

INSERT INTO dbo.refugios
    (id_refugio, razon_social, correo, telefono, domicilio, habilitacion_municipal, id_responsable)
VALUES
    (500001, 'Refugio Huellitas', 'contacto@huellitas.org', '3514445001', 'Camino a San Carlos 2500', 'REF-500001', 300001),
    (500002, 'Refugio Patitas Cordoba', 'contacto@patitascordoba.org', '3514445002', 'Av. Circunvalacion 4500', 'REF-500002', 300002);
GO

INSERT INTO dbo.rasgos_mascotas
    (cod_rasgo, nom_rasgo)
VALUES
    (1, 'Color'),
    (2, 'Tamano'),
    (3, 'Pelaje'),
    (4, 'Raza'),
    (5, 'Temperamento'),
    (6, 'Especie');
GO

INSERT INTO dbo.dominio_rasgos_mascotas
    (cod_rasgo, nro_valor_dominio, nom_valor_dominio)
VALUES
    (1, 1, 'Negro'),
    (1, 2, 'Blanco'),
    (1, 3, 'Marron'),
    (1, 4, 'Gris'),
    (1, 5, 'Canela'),
    (2, 1, 'Pequeno'),
    (2, 2, 'Mediano'),
    (2, 3, 'Grande'),
    (3, 1, 'Corto'),
    (3, 2, 'Largo'),
    (3, 3, 'Rizado'),
    (4, 1, 'Labrador'),
    (4, 2, 'Golden Retriever'),
    (4, 3, 'Caniche'),
    (4, 4, 'Mestizo'),
    (4, 5, 'Pastor Aleman'),
    (4, 6, 'Siames'),
    (4, 7, 'Persa'),
    (4, 8, 'Comun europeo'),
    (5, 1, 'Tranquilo'),
    (5, 2, 'Jugueton'),
    (5, 3, 'Nervioso'),
    (5, 4, 'Sociable'),
    (6, 1, 'Perro'),
    (6, 2, 'Gato'),
    (6, 3, 'Otro');
GO

INSERT INTO dbo.mascotas
    (nro_reg_municipal, nombre, sexo, año_nacimiento, microchip, vive, id_responsable, id_refugio)
VALUES
    ('MUN-000001', 'Luna', 'H', 2021, '985141000001', 'S', 100001, NULL),
    ('MUN-000002', 'Toby', 'M', 2020, '985141000002', 'S', 100002, NULL),
    ('MUN-000003', 'Mora', 'H', 2019, '985141000003', 'S', 100003, NULL),
    ('MUN-000004', 'Kira', 'H', 2022, '985141000004', 'S', NULL, 500001),
    ('MUN-000005', 'Rocky', 'M', 2020, '985141000005', 'S', NULL, 500001),
    ('MUN-000006', 'Nala', 'H', 2021, '985141000006', 'S', NULL, 500002),
    ('MUN-000007', 'Bruno', 'M', 2018, '985141000007', 'S', NULL, 500002);
GO

INSERT INTO dbo.caracteristicas_mascotas
    (nro_reg_municipal, cod_rasgo, nro_caracteristica, nro_valor_dominio, valor_caracteristica)
VALUES
    ('MUN-000001', 1, 1, 5, NULL),
    ('MUN-000001', 2, 1, 2, NULL),
    ('MUN-000001', 3, 1, 1, NULL),
    ('MUN-000001', 4, 1, 3, NULL),
    ('MUN-000001', 5, 1, 4, NULL),
    ('MUN-000001', 6, 1, 1, NULL),

    ('MUN-000002', 1, 1, 1, NULL),
    ('MUN-000002', 2, 1, 3, NULL),
    ('MUN-000002', 3, 1, 1, NULL),
    ('MUN-000002', 4, 1, 1, NULL),
    ('MUN-000002', 5, 1, 2, NULL),
    ('MUN-000002', 6, 1, 1, NULL),

    ('MUN-000003', 1, 1, 2, NULL),
    ('MUN-000003', 2, 1, 2, NULL),
    ('MUN-000003', 3, 1, 2, NULL),
    ('MUN-000003', 4, 1, 4, NULL),
    ('MUN-000003', 5, 1, 1, NULL),
    ('MUN-000003', 6, 1, 1, NULL),

    ('MUN-000004', 1, 1, 2, NULL),
    ('MUN-000004', 2, 1, 2, NULL),
    ('MUN-000004', 3, 1, 1, NULL),
    ('MUN-000004', 4, 1, 4, NULL),
    ('MUN-000004', 5, 1, 4, NULL),
    ('MUN-000004', 6, 1, 1, NULL),

    ('MUN-000005', 1, 1, 1, NULL),
    ('MUN-000005', 2, 1, 3, NULL),
    ('MUN-000005', 3, 1, 1, NULL),
    ('MUN-000005', 4, 1, 5, NULL),
    ('MUN-000005', 5, 1, 2, NULL),
    ('MUN-000005', 6, 1, 1, NULL),

    ('MUN-000006', 1, 1, 3, NULL),
    ('MUN-000006', 2, 1, 2, NULL),
    ('MUN-000006', 3, 1, 2, NULL),
    ('MUN-000006', 4, 1, 4, NULL),
    ('MUN-000006', 5, 1, 4, NULL),
    ('MUN-000006', 6, 1, 1, NULL),

    ('MUN-000007', 1, 1, 4, NULL),
    ('MUN-000007', 2, 1, 3, NULL),
    ('MUN-000007', 3, 1, 1, NULL),
    ('MUN-000007', 4, 1, 5, NULL),
    ('MUN-000007', 5, 1, 1, NULL),
    ('MUN-000007', 6, 1, 1, NULL);
GO

INSERT INTO dbo.profesionales_veterinarias
    (id_veterinaria, id_profesional, baja)
VALUES
    (400001, 200001, 'N'),
    (400001, 200002, 'N'),
    (400002, 200003, 'N'),
    (400003, 200004, 'N');
GO

INSERT INTO dbo.publicaciones_adopcion
    (nro_publicacion, nro_reg_municipal, id_refugio, fecha_publicacion,
     caracteristicas_mascota, condicion_adopcion, foto, estado_publicacion)
VALUES
    (600001, 'MUN-000004', 500001, '2026-08-01',
     'Hembra mediana, pelaje corto, color blanco, mestiza y sociable.',
     'Entrevista previa y seguimiento posterior a la adopcion.',
     'kira.jpg', 'ACTIVA'),

    (600002, 'MUN-000005', 500001, '2026-08-05',
     'Macho grande, pelaje corto, color negro, pastor aleman y jugueton.',
     'Patio cerrado y compromiso de controles veterinarios.',
     'rocky.jpg', 'ACTIVA'),

    (600003, 'MUN-000006', 500002, '2026-08-10',
     'Hembra mediana, pelaje largo, color marron, mestiza y sociable.',
     'Se requiere entrevista con el refugio.',
     'nala.jpg', 'ACTIVA'),

    (600004, 'MUN-000007', 500002, '2026-08-12',
     'Macho grande, pelaje corto, color gris, pastor aleman y tranquilo.',
     'Adopcion responsable con seguimiento.',
     'bruno.jpg', 'ACTIVA');
GO

INSERT INTO dbo.tipos_atencion_sanitaria
    (cod_tipo_atencion, desc_tipo_atencion)
VALUES
    (1, 'Vacunacion'),
    (2, 'Control veterinario'),
    (3, 'Desparasitacion'),
    (4, 'Tratamiento'),
    (5, 'Cirugia'),
    (6, 'Esterilizacion'),
    (7, 'Castracion');
GO

INSERT INTO dbo.informacion_sanitaria
    (nro_reg_municipal, nro_registro, fecha_atencion, cod_tipo_atencion,
     detalle_atencion, fecha_vencimiento, id_veterinaria, id_profesional)
VALUES
    ('MUN-000001', 1, '2026-03-15', 1,
     'Vacuna antirrabica', '2027-03-15', 400001, 200001),

    ('MUN-000001', 2, '2026-04-10', 2,
     'Control general', NULL, 400001, 200002),

    ('MUN-000002', 1, '2026-02-20', 1,
     'Vacuna sextuple', '2027-02-20', 400002, 200003),

    ('MUN-000003', 1, '2026-05-12', 3,
     'Desparasitacion interna', '2026-11-12', 400003, 200004),

    ('MUN-000004', 1, '2026-06-01', 1,
     'Vacuna antirrabica', '2027-06-01', 400001, 200001),

    ('MUN-000005', 1, '2026-06-05', 2,
     'Control veterinario general', NULL, 400001, 200002),

    ('MUN-000006', 1, '2026-06-15', 3,
     'Desparasitacion interna', '2026-12-15', 400002, 200003),

    ('MUN-000007', 1, '2026-07-01', 1,
     'Vacuna antirrabica', '2027-07-01', 400003, 200004);
GO


INSERT INTO dbo.atributos_sistema
    (cod_atributo, desc_atributo, tipo_dato, observ_atributo)
VALUES
    (1, 'URL del servicio', 'VARCHAR', 'URL del servicio web que expone la veterinaria.'),
    (2, 'Tecnologia del servicio', 'VARCHAR', 'Tecnologia del servicio de la veterinaria (REST o SOAP).'),
    (3, 'Parametros del servicio', 'VARCHAR', 'Parametros que se envian al invocar el servicio.'),
    (4, 'Api Key', 'VARCHAR', 'Clave de acceso al servicio de la veterinaria.');
GO


INSERT INTO dbo.configuracion_veterinarias
    (id_veterinaria, cod_atributo, valor)
VALUES
    (400001, 1, 'https://api.veterinariacordoba.com/servicio'),
    (400001, 2, 'REST'),
    (400001, 3, 'formato=json'),
    (400001, 4, 'APIKEY-400001-DEMO'),

    (400002, 1, 'https://api.vetalberdi.com/servicio'),
    (400002, 2, 'SOAP'),
    (400002, 3, 'version=1.1'),
    (400002, 4, 'APIKEY-400002-DEMO'),

    (400003, 1, 'https://api.vetnuevacordoba.com/servicio'),
    (400003, 2, 'REST'),
    (400003, 3, 'formato=json'),
    (400003, 4, 'APIKEY-400003-DEMO');
GO