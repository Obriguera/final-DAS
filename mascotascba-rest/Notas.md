

# Cómo viaja una request

Cuando un cliente llama a la API, el pedido pasa por estas piezas, en este orden:

1. **`ApiKeyFilter`**: revisa que el pedido traiga el header `X-API-Key` correcto. Si no, corta ahí con 400 o 401.
2. **Resource**: la clase que recibe el pedido HTTP, lee los datos (body, headers, parámetros) y llama al Repository.
3. **Repository**: ejecuta el procedimiento almacenado con `JdbcTemplate` y convierte el resultado en objetos Java.
4. **Procedimiento almacenado**: hace el trabajo real en SQL Server (validar, consultar, insertar).
5. De vuelta: el procedimiento devuelve filas, el Repository las transforma en objetos, y el Resource arma la respuesta HTTP.


Cada entidad tiene su propio par de clases: `PublicacionesResource` + `PublicacionesRepository`, `LoginResource` + `LoginRepository`. Una entidad nueva, un Resource y un Repository nuevos.

### Estructura de carpetas

- `config/`: filtros y configuración (hoy solo `ApiKeyFilter`).
- `resources/`: los endpoints HTTP.
- `repositories/`: el acceso a la base.
- `BE/`: las clases que transportan datos.
- `src/main/resources/application.properties`: la configuración (conexión a la base, API Key).



# Conexión con la base

Spring Boot arma casi todo solo. Lo único que se configura es `application.properties`:

```properties
spring.datasource.url=jdbc:sqlserver://${DB_HOST:localhost}:${DB_PORT:1433};databaseName=${DB_NAME:mascotascba};encrypt=false
spring.datasource.username=${DB_USER:mascotascba}
spring.datasource.password=${DB_PASSWORD:MascotasCBA}
security.api-key=${API_KEY:...}
```

La sintaxis `${DB_HOST:localhost}` significa: "usá la variable de entorno `DB_HOST`; si no existe, usá `localhost`". Sirve para cambiar de ambiente sin tocar el código.

Con eso Spring crea un `DataSource` (administra las conexiones) y un `JdbcTemplate` (la herramienta para ejecutar SQL). 

En el Repository solo hay que pedirlo con `@Autowired`:

```java
@Autowired
private JdbcTemplate jdbcTemplate;
```


# Procedimientos almacenados

Toda la lógica de datos está en procedimientos almacenados. Java solo los llama.

### Reglas que seguimos

1. **Los nombres de las columnas que devuelve el procedimiento deben coincidir con los nombres de las propiedades del BE.** Si el BE tiene `nroRegMunicipal`, la columna se tiene que llamar `nroRegMunicipal` (con ese alias en el `SELECT`). Así `BeanPropertyRowMapper` los une solo.
2. **Los ids que salen al cliente van encriptados** con `dbo.fn_cifrar_id(id)`. Nunca se devuelve el número interno.
3. **Los errores de negocio se devuelven como un resultset** con tres columnas: `resultado = 'ERROR'`, `codigo` y `mensaje`. No se usa `RAISERROR` ni `THROW` para esto.
4. **La autorización se verifica dentro del procedimiento** con una función `fn_*_autorizado`.

### Ejemplo: un procedimiento que valida y devuelve un error

```sql
CREATE OR ALTER PROCEDURE dbo.act_estado_publicacion
(
    @nro_publicacion VARCHAR(1024),
    @id_ciudadano    VARCHAR(1024),
    @id_refugio      VARCHAR(1024),
    @accion          VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_refugio_int INT =
        dbo.fn_refugio_autorizado(@id_ciudadano, @id_refugio);

    IF @id_refugio_int IS NULL
    BEGIN
        SELECT resultado = 'ERROR', codigo = 'NO_AUTORIZADO',
               mensaje = 'El usuario no esta autorizado para operar sobre el refugio';
        RETURN;
    END;

    -- ... resto de la lógica ...
END;
```

Cómo leerlo, paso a paso:

1. Recibe los ids cifrados tal como los mandó el cliente.
2. Le pregunta a la función si ese ciudadano es responsable de ese refugio. Si lo es, devuelve el id real (un `INT`); si no, `NULL`.
3. Si es `NULL`, devuelve un resultset de error y termina con `RETURN`. Java lo va a traducir a HTTP 403.
4. Si no, sigue con la lógica normal usando `@id_refugio_int`.

### Ejemplo: un procedimiento que devuelve una lista

`get_publicaciones` hace lo mismo para autorizar, pero cuando el usuario no está autorizado devuelve un listado **vacío** (`WHERE 1 = 0`) en lugar de un error, porque el resultado esperado es una lista. Para el resto, es un `SELECT` con alias que coinciden con `PublicacionBE`.


### Orden para ejecutar los scripts

1. `mascotascba - Funciones.sql`.
2. `mascotascba - Autenticación.sql`.
3. `mascotascba - Publicaciones.sql`.


# BE: las clases que transportan datos

Un `BE` es una clase simple con atributos privados, getters y setters. Representa los datos que entran o salen de una operación.

Convención del proyecto:

- Si el procedimiento **devuelve datos** → `XxxBE` (por ejemplo `PublicacionBE`, una por cada fila del listado).
- Si recibe **datos de entrada** en el body → `XxxDataBE` (por ejemplo `CrearPublicacionDataBE`, `CambioEstadoDataBE`).
- Si devuelve algo que no es una lista de filas (por ejemplo un `OK` con campos sueltos), no se crea BE: el Repository devuelve un `Map<String, Object>`.

Ejemplo reducido:

```java
public class CambioEstadoDataBE {
    private String nroPublicacion;
    private String accion;

    public String getNroPublicacion() { return nroPublicacion; }
    public void setNroPublicacion(String nroPublicacion) { this.nroPublicacion = nroPublicacion; }

    public String getAccion() { return accion; }
    public void setAccion(String accion) { this.accion = accion; }
}
```

El JSON que llega en el body (`{"nroPublicacion": "...", "accion": "PAUSAR"}`) se convierte solo en este objeto, porque los nombres del JSON coinciden con los de los atributos.

`LoginDataBE` es especial: se usa tanto para recibir (`cuil`, `clave`) como para devolver (`idCiudadano`, `idRefugio`, `idVeterinaria`, `razonSocial`, `rol`). Por eso el Resource borra la clave (`setClave(null)`) antes de responder.


# Repository

El Repository ejecuta procedimientos y convierte los resultados. No sabe nada de HTTP ni de seguridad.

### Dos formas de llamar un procedimiento

**Cuando devuelve una lista de filas** → `jdbcTemplate.query(...)` con un `BeanPropertyRowMapper`:

```java
public List<PublicacionBE> getPublicaciones(
        String idCiudadano, String idRefugio, String nombre, String estado) {

    return jdbcTemplate.query(
            "exec dbo.get_publicaciones @id_ciudadano=?, @id_refugio=?, @nombre=?, @estado=?",
            new BeanPropertyRowMapper<>(PublicacionBE.class),
            idCiudadano, idRefugio, nombre, estado
    );
}
```

**Cuando devuelve una sola fila con datos sueltos** (un OK o un ERROR) → `jdbcTemplate.queryForMap(...)`, que devuelve un `Map` con nombre de columna y valor:

```java
public Map<String, Object> cambiarEstado(
        String nroPublicacion, String idCiudadano, String idRefugio, String accion) {

    return jdbcTemplate.queryForMap(
            "exec dbo.act_estado_publicacion @nro_publicacion=?, @id_ciudadano=?, @id_refugio=?, @accion=?",
            nroPublicacion, idCiudadano, idRefugio, accion
    );
}
```

### Por qué usamos parámetros con nombre

Los `?` se llenan en el orden en que los pasás a Java. Si en el `exec` también ponés el nombre (`@id_refugio=?`), el procedimiento sabe qué es cada valor aunque alguien cambie el orden de sus parámetros. Sin nombres, un cambio de orden cruza datos sin que nada falle.

### Ejemplo con login

```java
public LoginDataBE autenticar(String cuil, String clave) {
    List<LoginDataBE> resultado = jdbcTemplate.query(
            "exec dbo.aut_usuario @cuil=?, @clave=?",
            new BeanPropertyRowMapper<>(LoginDataBE.class),
            cuil, clave
    );
    return resultado.isEmpty() ? null : resultado.get(0);
}
```

Si las credenciales son incorrectas, el procedimiento devuelve cero filas, y el Repository devuelve `null`. El Resource interpreta ese `null` como un 401.


# Resource

El Resource es la clase que expone las URLs. Sus tareas son: recibir el pedido, leer los datos, llamar al Repository, y armar la respuesta HTTP con el código correcto.

### Anotaciones que más usamos

|Anotación|Para qué sirve|
|---|---|
|`@RestController`|Marca la clase como controlador REST|
|`@RequestMapping("/publicaciones")`|Ruta base de toda la clase|
|`@GetMapping` / `@PostMapping` / `@PatchMapping`|Ruta y método HTTP de cada función|
|`@RequestBody`|Convierte el JSON del body en un objeto Java|
|`@RequestParam`|Lee un parámetro de la URL (`?nombre=manch`)|
|`@PathVariable`|Lee un valor dentro de la ruta (`/factorial/5`)|
|`@RequestHeader`|Lee un header (`X-Id-Refugio`)|

La ruta final es la base más la específica. Con `@RequestMapping("/publicaciones")` y `@PatchMapping("/estado")`, el endpoint es `PATCH /publicaciones/estado`. (El prefijo `/api/v2` sale de `server.servlet.context-path`.)

## Métodos HTTP

`GET` obtiene información, `POST` crea algo, `PUT` reemplaza, `PATCH` modifica parcialmente, `DELETE` elimina. La URL dice **qué recurso**, el método dice **qué se hace con él**.

### Ejemplo completo: cambiar el estado de una publicación

```java
@PatchMapping("/estado")
public ResponseEntity<Map<String, Object>> cambiarEstado(
        @RequestHeader("X-Id-Ciudadano") String idCiudadano,
        @RequestHeader("X-Id-Refugio") String idRefugio,
        @RequestBody CambioEstadoDataBE datos) {

    Map<String, Object> resultado = repository.cambiarEstado(
            datos.getNroPublicacion(), idCiudadano, idRefugio, datos.getAccion());

    if (!"OK".equals(resultado.get("resultado"))) {
        return ResponseEntity.status(estadoHttp(resultado)).body(resultado);
    }
    return ResponseEntity.ok(resultado);
}
```

Paso a paso:

1. Spring lee los dos headers y el body.
2. Se los pasa al Repository, que ejecuta el procedimiento.
3. Si el procedimiento devolvió algo distinto de `OK`, se traduce el `codigo` a un status HTTP con `estadoHttp`.
4. Si fue `OK`, se responde 200 con el resultado.

### Traducción de códigos de error

El procedimiento devuelve un `codigo` y el Resource lo convierte en HTTP:

|`codigo` del procedimiento|HTTP|
|---|---|
|`DATOS_INVALIDOS`|400|
|`NO_AUTORIZADO`|403|
|`NO_ENCONTRADO`|404|
|`ESTADO_INVALIDO`|409|

Esa traducción está en el método privado `estadoHttp`. Si se agrega un código nuevo, se agrega ahí.


# Seguridad

Hay que distinguir dos cosas:

- **Autenticación**: ¿quién es el que llama?
- **Autorización**: ¿qué puede hacer?

### Qué hace hoy el proyecto

**1. API Key (autenticación del consumidor).** Un filtro revisa en todas las rutas que venga el header `X-API-Key` con el valor configurado:

```java
@Component
public class ApiKeyFilter extends OncePerRequestFilter {

    @Value("${security.api-key}")
    private String configuredApiKey;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String apiKey = request.getHeader("X-API-Key");
        if (apiKey == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        if (!configuredApiKey.equals(apiKey)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        filterChain.doFilter(request, response);
    }
}
```

Lectura: si falta el header, 400; si no coincide, 401; si coincide, el pedido sigue hacia el Resource (`filterChain.doFilter`). El `return` sin llamar a `doFilter` es lo que corta el pedido.

**2. Autorización en los procedimientos.** Después del login, el cliente guarda `idCiudadano` e `idRefugio`, y los manda como headers en cada request a `/publicaciones`. El procedimiento verifica que ese ciudadano sea el responsable de ese refugio. Si no lo es, devuelve `NO_AUTORIZADO`.

### Los ids cifrados

Hacia el cliente nunca viaja el id real. Se cifra con `ENCRYPTBYPASSPHRASE`, usando el propio id como clave y como texto:

- Cifrar: `dbo.fn_cifrar_id(5)` devuelve un texto largo en hexadecimal.
- Cada vez da un resultado **distinto** para el mismo id, pero todos sirven para volver al id original.
- Por eso **no se comparan cadenas cifradas**. Para saber si dos cosas son la misma, se usa un dato real (por ejemplo `nroRegMunicipal`).

Para validar, `fn_id_coincide(cifrado, id)` descifra el valor usando ese `id` como clave y comprueba que el resultado sea el mismo `id`. Devuelve 1 o 0.

### Las funciones de autorización

Están en `mascotascba - Funciones.sql`. Hay una por rol y todas devuelven el id real o `NULL`:

|Función|Autoriza a...|
|---|---|
|`fn_ciudadano_autorizado(idCiudadano)`|Cualquier ciudadano habilitado|
|`fn_refugio_autorizado(idCiudadano, idRefugio)`|El responsable de ese refugio|
|`fn_veterinaria_autorizada(idCiudadano, idVeterinaria)`|Un profesional activo de esa veterinaria|


# Cómo agregar un endpoint nuevo 

Ejemplo: `GET /publicaciones/{nroPublicacion}` para ver el detalle de una publicación del refugio.

**Paso 1. El procedimiento.** En `Publicaciones.sql`, creá `get_publicacion_detalle` con `@id_ciudadano`, `@id_refugio` y `@nro_publicacion`. Empezá siempre autorizando:

```sql
DECLARE @id_refugio_int INT =
    dbo.fn_refugio_autorizado(@id_ciudadano, @id_refugio);
```

Si es `NULL`, devolvé error `NO_AUTORIZADO` (o un listado vacío, si el procedimiento devuelve una lista). Después hacé el `SELECT` con alias en camelCase.

**Paso 2. Probalo en SSMS** con un `execute` usando los ids reales (sección 3).

**Paso 3. El BE.** Si devuelve filas con datos, creá `PublicacionDetalleBE` con un atributo por cada columna, con el mismo nombre que el alias, más getters y setters.

**Paso 4. El Repository.** Agregá el método con `jdbcTemplate.query(...)` y nombres de parámetros:

```java
"exec dbo.get_publicacion_detalle @id_ciudadano=?, @id_refugio=?, @nro_publicacion=?"
```

**Paso 5. El Resource.** Agregá la función con `@GetMapping("/{nroPublicacion}")`, leyendo `@PathVariable` y los dos `@RequestHeader`. Llamá al Repository y devolvé la respuesta.

**Paso 6. Probar por HTTP** con Postman o curl, mandando los tres headers:

```
GET /api/v2/publicaciones/0200...
X-API-Key: <api-key>
X-Id-Ciudadano: <del login>
X-Id-Refugio: <del login>
```

**Paso 7. Documentar** el endpoint en `MascotasCBA - API REST.md`.


# Cómo agregar o quitar un atributo

### Agregar una columna a un listado

Por ejemplo, agregar `raza` al listado de publicaciones:

1. En el procedimiento, sumá la columna al `SELECT` con alias `raza`.
2. En `PublicacionBE`, agregá `private String raza;` con su getter y setter.
3. El Repository **no cambia**: `BeanPropertyRowMapper` une por nombre.
4. Actualizá el ejemplo de respuesta en la documentación.

### Agregar un campo de entrada

Por ejemplo, agregar `color` a `crear_publicacion`:

1. En el procedimiento, agregá el parámetro **con valor por defecto**: `@color VARCHAR(50) = NULL`. Así no se rompe nada mientras migrás.
2. En `CrearPublicacionDataBE`, agregá el atributo `color`, con getter y setter.
3. En el Repository, agregá `@color=?` al `exec` y el argumento al final.
4. En el Resource, pasá `datos.getColor()` al Repository.
5. Si el campo es obligatorio, agregá la validación en el procedimiento.

### Quitar un campo

Hacelo de afuera hacia adentro: primero Java deja de enviarlo (Resource y Repository), después sacalo del BE, y por último del procedimiento. Así, en ningún momento un lado le pide al otro algo que ya no existe.

