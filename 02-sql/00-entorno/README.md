# Montaje del entorno de base de datos

Instalación y configuración de PostgreSQL 18 y DBeaver en Windows, creación de una base de datos propia y carga de un dataset de cartera para trabajar sobre él con SQL.

Documento esto porque montar el entorno es el primer obstáculo real de cualquiera que empieza con bases de datos, y porque un proceso que no está escrito hay que volver a descubrirlo cada vez.

---

## Qué se instala y por qué son dos cosas

| | PostgreSQL | DBeaver |
|---|---|---|
| Qué es | El **servidor** de base de datos | El **cliente** |
| Qué hace | Guarda los datos, los protege y ejecuta las consultas | Muestra las bases y permite escribir consultas |
| ¿Tiene contraseña? | **Sí** — la del usuario `postgres` | No |
| Si lo desinstalo | Pierdo los datos | No pierdo nada |

Es la arquitectura **cliente-servidor**: el servidor manda y guarda; el cliente solo es una ventana. DBeaver podría cambiarse por cualquier otro cliente sin tocar los datos.

---

## 1. PostgreSQL

Instalador oficial de EDB desde [postgresql.org/download/windows](https://www.postgresql.org/download/windows/).

Decisiones tomadas durante la instalación:

| Pantalla | Valor | Por qué |
|---|---|---|
| Directorio de instalación | `C:\Program Files\PostgreSQL\18` | Por defecto. Aquí viven los ejecutables |
| Componentes | PostgreSQL Server, pgAdmin 4, Command Line Tools | **Stack Builder desmarcado**: solo instala extras innecesarios |
| Directorio de datos | `...\18\data` | Aquí viven las bases. **Esta es la carpeta que se respalda** |
| Contraseña | *(la del superusuario `postgres`)* | No es recuperable. Se anota antes de continuar |
| Puerto | `5432` | Estándar de PostgreSQL |
| Configuración regional | `[Default locale]` | Hereda el de Windows |

**El instalador no pide nombre de usuario** porque el superusuario se llama siempre `postgres`; solo hay que definir su contraseña.

---

## 2. DBeaver

Community Edition desde [dbeaver.io/download](https://dbeaver.io/download/). Instalación sin decisiones relevantes.

Configuración inicial elegida:

- **Vista del navegador: `Simplified`** — `Full` muestra catálogos del sistema, roles y tablespaces, que al empezar son ruido
- **Telemetría desactivada**

---

## 3. Conexión

```
Host:       localhost
Puerto:     5432
Base:       postgres
Usuario:    postgres
Contraseña: (la definida en la instalación)
```

La primera conexión pide **descargar los drivers JDBC de PostgreSQL**. Son necesarios: DBeaver está escrito en Java y los usa para comunicarse con el servidor. Se descargan una sola vez.

Resultado de `Probar conexión`:

```
Conectado (69 ms)
Server: PostgreSQL 18.6 on x86_64-windows
Driver: PostgreSQL JDBC Driver 42.7.13
```

Esas cinco líneas de conexión son las mismas que pide cualquier herramienta que se conecte a una base: Power BI, Python, n8n. Cambia `localhost` por la dirección del servidor y el resto es idéntico.

---

## 4. Base de datos propia

No se trabaja sobre la base `postgres`, que es administrativa del servidor. Cada proyecto lleva la suya:

```sql
CREATE DATABASE andina;
```

Para verla en el navegador hay que marcar **`Show all databases`** en las propiedades de la conexión y reconectar. La jerarquía queda así:

```
postgres (conexión)   →  servidor
 ├── andina           →  base de datos
 │    └── public      →  esquema
 │         └── cartera →  tabla
 └── postgres         →  base administrativa
```

**Servidor → base → esquema → tabla.** Antes de ejecutar cualquier script hay que verificar el selector superior de DBeaver: debe decir `public@andina`. Ejecutar el script correcto en la base equivocada no produce ningún error visible.

---

## 5. Carga de datos

El script [`cartera.sql`](cartera.sql) crea la tabla y carga 15 facturas de cartera al corte del 30/09/2026:

```sql
DROP TABLE IF EXISTS cartera;

CREATE TABLE cartera (
    factura            TEXT,
    cliente            TEXT,
    fecha_emision      DATE,
    fecha_vencimiento  DATE,
    valor              NUMERIC,
    dias_mora          INTEGER,
    estado             TEXT
);
```

Se ejecuta el script completo con `Alt + X` (`Ctrl + Intro` ejecuta solo una sentencia).

**`valor` se define como `NUMERIC` y no como `FLOAT`**: los decimales de coma flotante producen errores de redondeo que en cifras de dinero son inaceptables.

---

## 6. Verificación

```sql
SELECT COUNT(*) FROM cartera;
```

Devuelve `15`, y el panel de estadísticas confirma `Updated Rows: 15`.

Como control adicional, se contrastó un total contra el mismo cálculo hecho previamente en hoja de cálculo:

```sql
SELECT SUM(valor) FROM cartera WHERE estado = 'CRITICA';
```

Resultado: **1.700.000**, idéntico al obtenido con `SUMIFS`. Al migrar un proceso de una herramienta a otra, cuadrar un total conocido es la primera validación.

---

## Cosas que confunden la primera vez

**`NOTICE: table "cartera" does not exist`**
No es un error. Es un aviso que lanza `DROP TABLE IF EXISTS` cuando no hay nada que borrar, y la ejecución continúa. Un aviso informa; un error detiene.

**`Updated Rows: 0` al crear la base**
`CREATE DATABASE` no modifica filas, solo crea estructura. La ausencia de mensaje de error es la confirmación.

**El nombre de la pestaña del editor no indica la base**
Las pestañas se nombran por la conexión, no por la base activa. Lo que manda es el selector superior.

**La base nueva no aparece en el navegador**
Requiere marcar `Show all databases` **y reconectar**. Aplicar el cambio no basta.

---

## Archivos

| Archivo | Contenido |
|---|---|
| [`cartera.sql`](cartera.sql) | Script de creación y carga de la tabla |
| `img/` | Capturas del proceso de instalación y conexión |

## Entorno

Windows 11 · PostgreSQL 18.6 · DBeaver Community 26.2 · PostgreSQL JDBC Driver 42.7.13
