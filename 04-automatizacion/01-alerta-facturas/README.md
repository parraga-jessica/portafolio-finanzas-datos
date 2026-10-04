# Alerta automática de facturas próximas a vencer

Flujo de n8n que consulta la base de cartera cada mañana y envía un aviso por correo con las facturas que vencen en los próximos cinco días. Si no hay ninguna, no envía nada.

![Flujo en n8n](img/flujo-n8n.png)

---

## Problema

El [aging de cartera](../../02-sql/01-aging-cartera/) y el [tablero](../../03-bi/01-tablero-cartera/) responden preguntas cuando alguien las hace. Pero el aviso de un vencimiento próximo **no funciona así**: si nadie entra a mirar, la factura vence igual.

Hay información que no sirve de nada esperando a que la consulten. Tiene que salir a buscar a quien la necesita.

## El flujo

```
[Programación 8:00] → [Consulta SQL] → [Agregar] → [¿Hay facturas?] →(sí)→ [Correo]
                                                           └────────(no)→ fin
```

| Nodo | Qué hace |
|---|---|
| **Schedule Trigger** | Dispara el flujo cada día a las 8:00 |
| **Postgres** | Consulta `v_cartera_detalle` |
| **Aggregate** | Colapsa las facturas en un solo elemento |
| **If** | Comprueba si la lista trae algo |
| **Send Email** | Envía el resumen por SMTP |

La consulta:

```sql
SELECT factura, cliente, fecha_vencimiento, saldo, dias_mora
FROM v_cartera_detalle
WHERE dias_mora BETWEEN -5 AND 0
  AND saldo > 0
ORDER BY fecha_vencimiento;
```

Mora negativa significa que la factura **aún no ha vencido**. El rango `-5 a 0` son las que vencen dentro de los próximos cinco días, y el `saldo > 0` descarta las ya pagadas.

![Correo recibido](img/correo-recibido.png)

## Decisiones de diseño

**Un correo con el resumen, no uno por factura.** En n8n, cada fila que sale de un nodo hace que el siguiente se ejecute una vez. Una consulta que devuelve 50 facturas enviaría 50 correos. El nodo `Aggregate` colapsa todas las filas en un solo elemento antes de llegar al correo.

Por eso, antes de conectar cualquier nodo que haga algo irreversible —enviar, escribir, borrar—, hay que mirar **cuántos elementos** produce el nodo anterior. Es el equivalente de ejecutar un `SELECT` antes de un `DELETE`.

**Si no hay facturas, no se envía nada.** El nodo `If` corta el flujo cuando la lista viene vacía. Sin él, el `Aggregate` produciría igualmente un elemento y se enviaría un correo sin contenido.

Esa decisión aplica **cuando el destinatario es el cliente**. Para un reporte interno el criterio sería el contrario, y vale la pena explicar por qué:

> Un proceso automático que solo habla cuando tiene algo que decir es indistinguible de un proceso que dejó de funcionar.

Si el área de cartera no recibe el correo un martes, no puede saber si es porque no había vencimientos o porque el flujo se rompió. En un entorno real eso se resuelve enviando siempre —aunque diga "0 facturas"— o con una alerta independiente de fallo. **Una automatización rota es un error silencioso que puede durar semanas.**

**El destinatario es la propia cuenta.** Un flujo que envía correos a terceros no se prueba con datos de prueba: se prueba contra uno mismo hasta que funciona, y solo entonces se cambia el destinatario.

## Sobre las credenciales

El envío usa **SMTP con una contraseña de aplicación de Google**, no la contraseña de la cuenta. Es una clave generada para esta aplicación concreta, revocable por separado y sin acceso al resto de la cuenta.

Lo correcto en producción sería **OAuth**, que autoriza a la aplicación sin entregarle ninguna contraseña. n8n lo soporta; exige crear un proyecto en Google Cloud.

La distinción importa más que la implementación: **saber qué mecanismo estás usando y por qué** es la diferencia entre algo que funciona y algo que pondrías en producción.

Las credenciales se guardan cifradas en n8n y **no viajan en el archivo exportado**. Quien importe este flujo deberá configurar las suyas.

## Limitaciones

- **El flujo solo se ejecuta mientras n8n esté corriendo.** En local, eso significa con el equipo encendido y el proceso activo. En producción se despliega como servicio o en un servidor.
- El correo va a una dirección fija. Enviar a cada cliente exigiría tener sus correos en el maestro y cambiar el diseño a un envío por fila.
- No hay registro de qué se notificó ni cuándo. Un segundo paso natural sería escribir cada envío en una tabla de auditoría.

## Reproducir

1. Tener la base del [proyecto de aging](../../02-sql/01-aging-cartera/) cargada en PostgreSQL
2. Instalar n8n: `npx n8n`
3. Importar `alerta-facturas.json` desde el menú del editor
4. Configurar las credenciales: PostgreSQL y SMTP
5. Activar el flujo

## Herramientas

n8n · PostgreSQL · SMTP · expresiones JavaScript para el formato del mensaje
