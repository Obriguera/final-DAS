# Autenticación y autorización

Hay un único control de acceso a nivel HTTP y la autorización de cada operación la hacen los procedimientos almacenados.

| Qué se controla | Quién lo hace | Header | Se aplica a |
| --- | --- | --- | --- |
| Que quien llama sea un consumidor autorizado de la API | `ApiKeyFilter` | `X-API-Key` | **Todas** las rutas (incluido `/login`) |
| Que el usuario pueda operar sobre el refugio | Procedimiento almacenado | `X-Id-Ciudadano` y `X-Id-Refugio` | Rutas de `/publicaciones` |

### API Key

```
X-API-Key: UBPU5iOKq7Cne3p3mzdrwEpBj7XyQsaiXq6
```

### Identificación del usuario

`POST /login` devuelve `idCiudadano` e `idRefugio` (encriptados). El cliente los guarda y los envía en cada request a `/publicaciones`:

```
X-Id-Ciudadano: 02000000...
X-Id-Refugio: 02000000...
```

El procedimiento descifra ambos valores y verifica que:

1. el refugio exista;
2. el ciudadano esté habilitado;
3. ese ciudadano sea el responsable de ese refugio.

Si alguna condición falla, la operación no se ejecuta y se devuelve `NO_AUTORIZADO` (`403`). Así, un refugio solo puede operar sobre sus propias publicaciones.

### Autorización por rol

| Ruta | Quién puede usarla |
| --- | --- |
| `/login` | Pública (solo requiere API Key) |
| `/publicaciones/**` | El ciudadano responsable del refugio indicado en los headers |

Los roles que existen en el sistema son `REFUGIO`, `PROFESIONAL` y `CIUDADANO`. El servidor **no** valida el rol por ruta: valida la relación entre los datos (ciudadano responsable del refugio). El campo `rol` que devuelve el login le sirve al cliente para decidir qué pantallas mostrar. Un usuario que no sea responsable del refugio indicado recibe `403`.

> **Limitación:** los identificadores encriptados no prueban que el usuario haya iniciado sesión, solo que corresponden a registros reales. La API Key es la única barrera de acceso general.


# Endpoints

### POST /login

Autentica un usuario y devuelve sus identificadores y su rol.

**Headers**

| Header | Valor |
|---|---|
| `X-API-Key` | `<api-key>` |
| `Content-Type` | `application/json` |

**Body**

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `cuil` | string | Sí | CUIL del usuario |
| `clave` | string | Sí | Clave del usuario |

```json
{
  "cuil": "27456789012",
  "clave": "clave300001"
}
```

**Respuesta `200 OK`**

```json
{
  "cuil": "27456789012",
  "clave": null,
  "idCiudadano": "02000000...",
  "idRefugio": "02000000...",
  "idVeterinaria": null,
  "razonSocial": "Refugio Huellitas",
  "rol": "REFUGIO"
}
```

| Campo | Descripción |
|---|---|
| `idCiudadano` | Identificador del usuario (encriptado) |
| `idRefugio` | Identificador del refugio (solo rol `REFUGIO`, encriptado) |
| `idVeterinaria` | Identificador de la veterinaria (solo rol `PROFESIONAL`, encriptado) |
| `razonSocial` | Nombre del refugio o veterinaria; `null` para ciudadanos |
| `rol` | `REFUGIO`, `PROFESIONAL` o `CIUDADANO` |

**Errores**

| Status | Causa |
|---|---|
| `401` | Credenciales incorrectas (body vacío) |


### GET /publicaciones

Lista las publicaciones del refugio indicado, ordenadas de la más reciente a la más antigua.

**Headers:** `X-API-Key`, `X-Id-Ciudadano`, `X-Id-Refugio`

**Query params** (todos opcionales y combinables)

| Parámetro | Tipo | Descripción |
|---|---|---|
| `nombre` | string | Filtra por nombre de la mascota (búsqueda parcial, `LIKE '%valor%'`) |
| `estado` | string | `ACTIVA`, `PAUSADA` o `FINALIZADA`. No distingue mayúsculas/minúsculas |

**Ejemplo**

```
GET /api/v2/publicaciones?nombre=manch&estado=ACTIVA
X-API-Key: <api-key>
X-Id-Ciudadano: 02000000...
X-Id-Refugio: 02000000...
```

**Respuesta `200 OK`**

```json
[
  {
    "nroPublicacion": "0200000079FF86132AC5...",
    "nroRegMunicipal": "MUN-000001",
    "nombre": "Manchita",
    "especie": "Perro",
    "sexo": "H",
    "edad": 2,
    "caracteristicasMascota": "Cariñosa y tranquila.",
    "condicionAdopcion": "Entrevista previa y compromiso de tenencia responsable.",
    "foto": "manchita.jpg",
    "estadoPublicacion": "ACTIVA",
    "fechaPublicacion": "2026-10-07"
  }
]
```

| Campo | Descripción |
|---|---|
| `nroPublicacion` | Identificador de la publicación (encriptado, ver [nota](#identificadores-encriptados)) |
| `nroRegMunicipal` | Registro municipal de la mascota (`MUN-000001`, ...) |
| `especie` | `Perro`, `Gato` u `Otro` |
| `sexo` | `H` (hembra) o `M` (macho) |
| `edad` | Edad en años; `null` si no se conoce |
| `estadoPublicacion` | `ACTIVA`, `PAUSADA` o `FINALIZADA` |
| `fechaPublicacion` | Fecha de alta de la publicación |

Si no hay resultados devuelve `[]`. También devuelve `[]` cuando el usuario no está autorizado sobre el refugio indicado (el listado no distingue ambos casos, para no revelar si el refugio existe).


### POST /publicaciones

Crea una nueva publicación de adopción. En una sola transacción da de alta la mascota, sus características (especie y raza) y la publicación, que queda en estado `ACTIVA`.

**Headers:** `X-API-Key`, `X-Id-Ciudadano`, `X-Id-Refugio`, `Content-Type: application/json`

**Body**

| Campo | Tipo | Requerido | Validación |
|---|---|---|---|
| `nombre` | string | Sí | Máximo 100 caracteres |
| `especie` | string | Sí | Debe existir en el dominio de especies (`Perro`, `Gato`, `Otro`) |
| `sexo` | string | Sí | `Hembra` / `Macho` (o `H` / `M`). Se toma la primera letra |
| `edadAproximada` | string | No | Número seguido de texto opcional: `"2"`, `"2 años"`, `"6 meses"`. Máximo 40 años |
| `raza` | string | No | Máximo 200 caracteres. Si coincide con el dominio se guarda el valor; si no, como texto libre |
| `caracteristicasMascota` | string | Sí | Descripción general. Máximo 500 caracteres |
| `condicionAdopcion` | string | Sí | Máximo 300 caracteres |
| `foto` | string | Sí | Nombre o ruta de la foto. Máximo 300 caracteres |

```json
{
  "nombre": "Manchita",
  "especie": "Perro",
  "sexo": "Hembra",
  "edadAproximada": "2 años",
  "raza": "Mestizo",
  "caracteristicasMascota": "Cariñosa y tranquila.",
  "condicionAdopcion": "Entrevista previa y compromiso de tenencia responsable.",
  "foto": "manchita.jpg"
}
```

**Respuesta `201 Created`**

```json
{
  "resultado": "OK",
  "nroPublicacion": "0200000079FF86132AC5...",
  "nroRegMunicipal": "MUN-000001",
  "estadoPublicacion": "ACTIVA"
}
```

**Respuesta de error `400 Bad Request`**

```json
{
  "resultado": "ERROR",
  "codigo": "DATOS_INVALIDOS",
  "mensaje": "El sexo debe ser Hembra o Macho"
}
```

**Mensajes de error posibles**

| Mensaje | Causa |
|---|---|
| El nombre es obligatorio (maximo 100 caracteres) | Vacío o demasiado largo |
| El sexo debe ser Hembra o Macho | Sexo distinto de H/M |
| La descripcion es obligatoria (maximo 500 caracteres) | `caracteristicasMascota` vacío o largo |
| Las condiciones de adopcion son obligatorias (maximo 300 caracteres) | `condicionAdopcion` vacío o largo |
| La fotografia es obligatoria | `foto` vacía o larga |
| La raza es demasiado larga | `raza` de más de 200 caracteres |
| La edad aproximada no es valida (ej: 2 años) | Formato no numérico o mayor a 40 años |
| Especie invalida | La especie no existe en el dominio |
| El usuario no esta autorizado para operar sobre el refugio (`403`) | El refugio no existe o el ciudadano no es su responsable |


### PATCH /publicaciones/estado

Cambia el estado de una publicación del refugio indicado.

**Headers:** `X-API-Key`, `X-Id-Ciudadano`, `X-Id-Refugio`, `Content-Type: application/json`

**Body**

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `nroPublicacion` | string | Sí | Identificador devuelto al crear o listar |
| `accion` | string | Sí | `PAUSAR`, `ACTIVAR` o `FINALIZAR` (sin distinguir mayúsculas) |

```json
{
  "nroPublicacion": "0200000079FF86132AC5...",
  "accion": "PAUSAR"
}
```

**Respuesta `200 OK`**

```json
{
  "resultado": "OK",
  "estadoPublicacion": "PAUSADA"
}
```

**Respuesta de error `409 Conflict`**

```json
{
  "resultado": "ERROR",
  "codigo": "ESTADO_INVALIDO",
  "mensaje": "Accion no permitida para el estado actual"
}
```

**Transiciones permitidas**

| Estado actual | Acción | Nuevo estado |
|---|---|---|
| `ACTIVA` | `PAUSAR` | `PAUSADA` |
| `ACTIVA` | `FINALIZAR` | `FINALIZADA` |
| `PAUSADA` | `ACTIVAR` | `ACTIVA` |
| `PAUSADA` | `FINALIZAR` | `FINALIZADA` |

Cualquier otra combinación devuelve `409`.
`FINALIZADA` es un estado terminal.



# Códigos de respuesta y errores

## Formato de error de negocio

Los errores generados por los procedimientos tienen esta forma:

```json
{
  "resultado": "ERROR",
  "codigo": "<CODIGO>",
  "mensaje": "<descripcion legible>"
}
```

## Mapeo código del SP a HTTP

| `codigo` | HTTP | Cuándo |
|---|---|---|
| `DATOS_INVALIDOS` | `400` | Falla alguna validación del body |
| `NO_AUTORIZADO` | `403` | El refugio no existe o el ciudadano no es su responsable |
| `NO_ENCONTRADO` | `404` | Publicación inexistente, o que no pertenece al refugio |
| `ESTADO_INVALIDO` | `409` | Transición de estado no permitida, o la publicación cambió de estado mientras se operaba |

## Errores de seguridad

| Status | Causa | Body |
|---|---|---|
| `400` | Falta el header `X-API-Key` | vacío |
| `401` | `X-API-Key` incorrecta | vacío |
| `400` | Falta el header `X-Id-Ciudadano` o `X-Id-Refugio` en `/publicaciones` | Error estándar de Spring |
| `401` | Login con credenciales incorrectas | vacío |
| `403` | Ciudadano no autorizado sobre el refugio (`NO_AUTORIZADO`) | JSON de error de negocio |



# Reglas de negocio

## Identificadores encriptados

`idCiudadano`, `idRefugio`, `idVeterinaria` y `nroPublicacion` se exponen **encriptados** (`ENCRYPTBYPASSPHRASE`), nunca como el número interno. Tener en cuenta que:

- El valor encriptado **cambia en cada llamada** para el mismo registro (el algoritmo usa un salt aleatorio), pero todos los valores son válidos y desencriptan al mismo id.
- Por eso **no deben compararse como strings** para saber si dos publicaciones son la misma; usar `nroRegMunicipal` para eso.
- En cada operación se valida que el ciudadano sea el responsable del refugio indicado y que la publicación pertenezca a ese refugio.

## Cómo se autoriza dentro de la base

Los procedimientos usan funciones compartidas definidas en `mascotascba - Funciones.sql`:

| Función | Devuelve |
|---|---|
| `fn_cifrar_id(id)` | El id encriptado que se envía al cliente |
| `fn_id_coincide(id_cifrado, id)` | `1` si el valor cifrado corresponde a ese id, `0` si no |
| `fn_ciudadano_autorizado(idCiudadano)` | Id real del ciudadano habilitado, o `NULL` |
| `fn_refugio_autorizado(idCiudadano, idRefugio)` | Id real del refugio si el ciudadano es su responsable, o `NULL` |
| `fn_veterinaria_autorizada(idCiudadano, idVeterinaria)` | Id real de la veterinaria si el ciudadano es profesional activo de ella, o `NULL` |

### Alta de publicación

1. Se calcula el próximo `nro_reg_municipal` con formato `MUN-` + 6 dígitos (`MUN-000001`, `MUN-000002`, ...).
2. Se inserta la mascota con `vive = 'S'` y sin responsable ni microchip.
3. Se registra la **especie** como característica (`cod_rasgo = 6`).
4. Si se informó **raza**, se registra como característica (`cod_rasgo = 4`): con el valor del dominio si hay coincidencia exacta, o como texto libre.
5. Se inserta la publicación con la fecha actual y estado `ACTIVA`.

Todo ocurre dentro de una transacción: si algo falla, no se guarda nada.

### Edad

- En el alta, `edadAproximada` se convierte a **año de nacimiento** (`año actual − edad`). Si el texto contiene `mes`, el número se divide por 12.
- En el listado, `edad` se calcula como `año actual − año de nacimiento`, o `null` si no hay año de nacimiento.

### Concurrencia en cambio de estado

El `UPDATE` incluye el estado actual en el `WHERE`. Si otro usuario cambió el estado entre la lectura y la escritura, devuelve `409` con el mensaje *"La publicacion cambio de estado, actualice el listado"*.