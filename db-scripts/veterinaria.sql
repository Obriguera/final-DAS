USE veterinaria;
GO

DROP TABLE IF EXISTS dbo.detalle_atencion_sanitaria;
DROP TABLE IF EXISTS dbo.atencion_sanitaria;
DROP TABLE IF EXISTS dbo.responsables_mascotas;
DROP TABLE IF EXISTS dbo.profesionales;
DROP TABLE IF EXISTS dbo.mascotas;
DROP TABLE IF EXISTS dbo.razas;
DROP TABLE IF EXISTS dbo.especies;
DROP TABLE IF EXISTS dbo.vacunas;
DROP TABLE IF EXISTS dbo.tipos_atencion_sanitaria;
DROP TABLE IF EXISTS dbo.configuracion_sistema;
DROP TABLE IF EXISTS dbo.personas;
GO


CREATE TABLE personas (
    id_persona      INT             NOT NULL,
    apellido        VARCHAR(100)    NOT NULL,
    nombre          VARCHAR(100)    NOT NULL,
    tipo_documento  VARCHAR(20)     NOT NULL,
    nro_documento   VARCHAR(30)     NOT NULL,
    correo          VARCHAR(150),
    telefono        VARCHAR(30),
    domicilio       VARCHAR(200),

    CONSTRAINT pk_personas
        PRIMARY KEY (id_persona)
);
GO


CREATE TABLE especies (
    cod_especie     INT             NOT NULL,
    desc_especie    VARCHAR(100)    NOT NULL,

    CONSTRAINT pk_especies
        PRIMARY KEY (cod_especie)
);
GO


CREATE TABLE razas (
    cod_especie     INT             NOT NULL,
    id_raza         INT             NOT NULL,
    nom_raza        VARCHAR(100)    NOT NULL,

    CONSTRAINT pk_razas
        PRIMARY KEY (cod_especie, id_raza),

    CONSTRAINT fk_razas_especies
        FOREIGN KEY (cod_especie)
        REFERENCES especies (cod_especie)
);
GO


CREATE TABLE mascotas (
    id_mascota          INT             NOT NULL,
    nombre              VARCHAR(100)    NOT NULL,
    cod_especie         INT             NOT NULL,
    id_raza             INT,
    sexo                CHAR(1),
    fecha_nacimiento    DATE,
    color               VARCHAR(100),
    pelaje              VARCHAR(100),
    microchip           VARCHAR(50),
    vive                CHAR(1),
    nro_reg_municipal   VARCHAR(30),

    CONSTRAINT pk_mascotas
        PRIMARY KEY (id_mascota),

    CONSTRAINT fk_mascotas_razas
        FOREIGN KEY (cod_especie, id_raza)
        REFERENCES razas (cod_especie, id_raza)
);
GO


CREATE TABLE responsables_mascotas (
    id_mascota      INT             NOT NULL,
    id_persona      INT             NOT NULL,
    fecha_desde     DATE            NOT NULL,
    fecha_hasta     DATE,
    observaciones   VARCHAR(500),
    principal       CHAR(1),

    CONSTRAINT pk_responsables_mascotas
        PRIMARY KEY (id_mascota, id_persona),

    CONSTRAINT fk_respmasc_mascotas
        FOREIGN KEY (id_mascota)
        REFERENCES mascotas (id_mascota),

    CONSTRAINT fk_respmasc_personas
        FOREIGN KEY (id_persona)
        REFERENCES personas (id_persona)
);
GO


CREATE TABLE profesionales (
    id_persona              INT             NOT NULL,
    matricula_profesional   VARCHAR(50)     NOT NULL,
    fecha_inicio            DATE,
    fecha_fin               DATE,

    CONSTRAINT pk_profesionales
        PRIMARY KEY (id_persona),

    CONSTRAINT fk_profesionales_personas
        FOREIGN KEY (id_persona)
        REFERENCES personas (id_persona)
);
GO


CREATE TABLE tipos_atencion_sanitaria (
    cod_tipo_atencion   INT             NOT NULL,
    desc_tipo_atencion  VARCHAR(100)    NOT NULL,

    CONSTRAINT pk_tipos_atencion_sanitaria
        PRIMARY KEY (cod_tipo_atencion)
);
GO


CREATE TABLE vacunas (
    cod_vacuna      INT             NOT NULL,
    nom_vacuna      VARCHAR(100)    NOT NULL,
    desc_vacuna     VARCHAR(300),

    CONSTRAINT pk_vacunas
        PRIMARY KEY (cod_vacuna)
);
GO


CREATE TABLE atencion_sanitaria (
    id_mascota          INT             NOT NULL,
    nro_atencion        INT             NOT NULL,
    id_profesional      INT,
    fecha_atencion      DATE            NOT NULL,
    fecha_prox_atencion DATE,
    observ_atencion     VARCHAR(500),

    CONSTRAINT pk_atencion_sanitaria
        PRIMARY KEY (id_mascota, nro_atencion),

    CONSTRAINT fk_atencsan_mascotas
        FOREIGN KEY (id_mascota)
        REFERENCES mascotas (id_mascota),

    CONSTRAINT fk_atencsan_profesionales
        FOREIGN KEY (id_profesional)
        REFERENCES profesionales (id_persona)
);
GO


CREATE TABLE detalle_atencion_sanitaria (
    id_mascota              INT             NOT NULL,
    nro_atencion            INT             NOT NULL,
    cod_tipo_atencion       INT             NOT NULL,
    nro_detalle             INT             NOT NULL,
    cod_vacuna              INT,
    lote_vacuna             VARCHAR(100),
    fecha_prox_vacunacion   DATE,
    indicaciones            VARCHAR(500),
    intervencion            VARCHAR(500),

    CONSTRAINT pk_detalle_atencion_sanitaria
        PRIMARY KEY (id_mascota, nro_atencion, cod_tipo_atencion, nro_detalle),

    CONSTRAINT fk_detatencsan_atencsan
        FOREIGN KEY (id_mascota, nro_atencion)
        REFERENCES atencion_sanitaria (id_mascota, nro_atencion),

    CONSTRAINT fk_detatencsan_tipos
        FOREIGN KEY (cod_tipo_atencion)
        REFERENCES tipos_atencion_sanitaria (cod_tipo_atencion),

    CONSTRAINT fk_detatencsan_vacunas
        FOREIGN KEY (cod_vacuna)
        REFERENCES vacunas (cod_vacuna)
);
GO


CREATE TABLE configuracion_sistema (
    clave_primaria      VARCHAR(100)    NOT NULL,
    clave_secundaria    VARCHAR(100)    NOT NULL,
    desc_clave          VARCHAR(200),
    tipo_dato           VARCHAR(30),
    valor               VARCHAR(500),

    CONSTRAINT pk_configuracion_sistema
        PRIMARY KEY (clave_primaria, clave_secundaria)
);
GO