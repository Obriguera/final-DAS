# final-DAS

Repositorio del proyecto final de Diseño Avanzado de Software (2026).

## Mapa general

```text
final-DAS/
├── mascotas-cba-frontend/   Aplicación web Angular
├── mascotascba-rest/        API REST con Spring Boot
├── mascotascba-soap/        Servicio SOAP con Spring Boot
├── db-scripts/              Scripts SQL de la base de datos
└── README.md                Documentación general del repositorio
```

## Frontend

Aplicación Angular. El código de la aplicación está en `src/app`; allí se agrupan las pantallas, servicios, interceptores y configuración de rutas.

```text
mascotas-cba-frontend/
├── public/                  Recursos estáticos
└── src/
	├── app/
	│   ├── environments/     Configuración por entorno
	│   ├── interceptors/     Interceptores HTTP
	│   ├── login-component/  Pantalla y lógica de inicio de sesión
	│   ├── placeholder/      Componente de contenido provisional
	│   └── services/         Acceso a recursos de la API
	├── index.html            Documento HTML principal
	├── main.ts               Inicio de la aplicación cliente
	├── main.server.ts        Inicio para renderizado en servidor
	└── styles.scss           Estilos globales
```

## Backend REST

API REST implementada con Spring Boot. Las clases Java se organizan en recursos HTTP, repositorios, configuración y objetos de datos; la carpeta de pruebas acompaña al código principal.

```text
mascotascba-rest/
└── src/
	├── main/
	│   ├── java/.../mascotascbarest/
	│   │   ├── BE/             Objetos de datos y entidades
	│   │   ├── config/         Filtros y configuración web
	│   │   ├── repositories/   Acceso a datos
	│   │   └── resources/      Endpoints REST
	│   └── resources/          application.properties y recursos web
	└── test/java/             Pruebas automatizadas
```

## Backend SOAP

Servicio SOAP desarrollado también con Spring Boot. Separa los contratos e implementaciones del servicio, la configuración, los repositorios y los objetos de datos.

```text
mascotascba-soap/
└── src/
	├── main/
	│   ├── java/.../mascotascbasoap/
	│   │   ├── be/           Objetos de datos y entidades
	│   │   ├── config/       Configuración SOAP y de servicios
	│   │   ├── repositories/ Acceso a datos
	│   │   └── services/     Contrato e implementación del servicio
	│   └── resources/        application.properties y recursos web
	└── test/java/            Pruebas automatizadas
```

## Base de datos

`db-scripts/` contiene el esquema y los scripts SQL agrupados por funcionalidad.

```text
db-scripts/
├── mascotascba.sql                  Esquema principal
├── mascotascba - Autenticación.sql  Funciones de autenticación
├── mascotascba - Funciones.sql      Funciones compartidas
├── mascotascba - Publicaciones.sql  Operaciones de publicaciones
└── veterinaria.sql                  Esquema de veterinaria
```
