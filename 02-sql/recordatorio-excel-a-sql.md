# De la pregunta de negocio a la consulta

Tabla de decisión para traducir lo que pide un gerente a la herramienta correcta, en hoja de cálculo y en SQL. Incluye las trampas de cada una: los errores que **no producen ningún mensaje** y devuelven un número creíble.

---

## 1. El verbo decide la función

Antes de escribir nada, identificar qué pide la pregunta. Tres verbos que suenan parecido y piden cosas distintas:

| Pregunta | Pide | Excel | SQL |
|---|---|---|---|
| **"¿Cuánto…?"** | Un total | `SUMIFS` | `SUM` |
| **"¿Cuántos/as…?"** | Un conteo | `COUNTIFS` | `COUNT` |
| **"¿Cuáles…?"** | Una lista | Filtro | `SELECT` + `WHERE` |
| **"¿Cuánto por cada…?"** | Un resumen | Tabla dinámica | `GROUP BY` |

Responder con una lista cuando piden un total, o con un total cuando piden una lista, es el error más frecuente y el más fácil de evitar.

---

## 2. Tabla de decisión

| El gerente pregunta | Excel / Sheets | SQL |
|---|---|---|
| ¿Cuánto nos deben en total? | `SUM` | `SELECT SUM(valor)` |
| ¿Cuánto nos debe este cliente? | `SUMIFS` | `SUM` + `WHERE` |
| ¿Cuántas facturas están vencidas? | `COUNTIFS` | `COUNT(*)` + `WHERE` |
| ¿Cuánto debe cada cliente? | Tabla dinámica | `GROUP BY cliente` |
| ¿Qué clientes deben más de X? | Tabla dinámica + filtro | `GROUP BY` + **`HAVING`** |
| ¿Cuál es la factura más atrasada? | Ordenar y mirar la primera | `ORDER BY ... DESC LIMIT 1` |
| ¿Qué clientes distintos tenemos? | `UNIQUE` | `SELECT DISTINCT` |
| Tráeme el dato de la otra tabla | `XLOOKUP` / `BUSCARX` | `LEFT JOIN` |
| ¿Qué hay en una lista y no en la otra? | `XLOOKUP` + `IFNA` | **anti-join** (`LEFT JOIN` + `IS NULL`) |
| Clasifícame esto en rangos | `IFS` / `SI.CONJUNTO` | `CASE WHEN` |
| Clasifícame contra una tabla de rangos | `BUSCARV` aproximado | `JOIN ... ON ... BETWEEN` |
| Si está vacío, pon cero | `SI.ND` / `IFNA` | `COALESCE` |
| Un tramo por columna | Tabla dinámica | `SUM(CASE WHEN ... THEN ... END)` |
| Subtotales y total general | Tabla dinámica | `GROUP BY ROLLUP` |
| ¿Qué % representa cada fila del total? | Fórmula con el total fijo | `SUM(...) OVER ()` |
| ¿Cuál es el acumulado? | Suma con rango que crece | `SUM(...) OVER (ORDER BY ...)` |
| ¿Cómo va contra el mes anterior? | Referencia a la celda de arriba | `LAG(...) OVER (ORDER BY ...)` |
| Ranking de clientes | `JERARQUIA` / ordenar | `RANK()` / `ROW_NUMBER()` |
| Quítame los duplicados | Quitar duplicados | `ROW_NUMBER()` + `WHERE rn = 1` |
| Clasifícame en A, B y C | Ordenar y partir a mano | `NTILE(3)` |

---

## 3. Equivalencia de funciones

| Excel (ES) | Excel (EN) | SQL |
|---|---|---|
| `SI` | `IF` | `CASE WHEN ... THEN ... ELSE ... END` |
| `SI.CONJUNTO` | `IFS` | `CASE WHEN` encadenado |
| `Y` / `O` | `AND` / `OR` | `AND` / `OR` |
| `SI.ND` | `IFNA` | `COALESCE` |
| `BUSCARV` exacto | `VLOOKUP` (FALSE) | `JOIN ... ON a = b` |
| `BUSCARV` aproximado | `VLOOKUP` (TRUE) | `JOIN ... ON x BETWEEN d AND h` |
| `BUSCARX` | `XLOOKUP` | `LEFT JOIN` |
| `SUMAR.SI.CONJUNTO` | `SUMIFS` | `SUM` + `WHERE` / `GROUP BY` |
| `CONTAR.SI.CONJUNTO` | `COUNTIFS` | `COUNT` + `WHERE` |
| `CONTARA(UNICOS(...))` | `COUNTA(UNIQUE(...))` | `COUNT(DISTINCT ...)` |
| `MAYUSC` | `UPPER` | `UPPER` |
| `ESPACIOS` | `TRIM` | `TRIM` |
| `SUSTITUIR` | `SUBSTITUTE` | `REPLACE` |
| `CONCATENAR` / `&` | `&` | `\|\|` o `CONCAT` |
| `FIN.MES` | `EOMONTH` | `DATE_TRUNC` + intervalos |

**En SQL las palabras clave son siempre en inglés**, en cualquier motor y cualquier país. No existen alias por idioma.

---

## 4. Trampas que no dan error

Las que importan: ninguna produce un mensaje, todas devuelven un resultado creíble.

### En SQL

**`INNER JOIN` excluye en silencio.** Una fila sin pareja no genera aviso: desaparece del resultado y del total. En reportes financieros, usar `LEFT JOIN` por defecto.

**Un JOIN uno-a-varios infla los totales.** Cruzar facturas con pagos cuando una factura tiene tres abonos repite su valor tres veces. Cada fila es correcta; sumarlas no.
→ **Detección:** `COUNT(*)` contra `COUNT(DISTINCT llave)` después de cada JOIN.
→ **Solución:** agregar antes de unir.

**`NOT IN` con nulos devuelve cero filas.** No una fila de menos: ninguna. Si la subconsulta trae un solo `NULL`, el filtro se vacía entero.
→ **Solución:** anti-join con `LEFT JOIN ... IS NULL`.

**Un anti-join con `INNER JOIN` no puede encontrar nada.** El `INNER` ya eliminó las filas sin pareja, así que el `IS NULL` posterior filtra sobre un conjunto vacío. Es válido y está garantizado que no detecte.

**Olvidar el `WHERE`.** En un `SELECT` devuelve de más; en un `UPDATE` o `DELETE` modifica la tabla entera.
→ **Regla:** correr todo `UPDATE`/`DELETE` primero como `SELECT`, con el mismo `WHERE`.

**El `WHERE` no conoce los alias.** Se ejecuta antes que el `SELECT`. Para filtrar por un cálculo hay que repetir la expresión o envolver la consulta.

**Condición de la tabla derecha en el `WHERE` de un `LEFT JOIN`.** Lo convierte en `INNER` sin avisar: las filas sin pareja tienen `NULL` y el `WHERE` las descarta. Va en el `ON`.

**Las comparaciones de texto distinguen mayúsculas.** `'al dia'` y `'AL DIA'` son distintos. Con `NOT IN` el error devuelve de más, que se nota menos que devolver de menos.

**Tramos solapados en una tabla de rangos.** Si un tramo empieza donde el anterior no ha terminado, las filas se duplican. Los límites son un contrato entre filas vecinas.

**`NULL` no es `0`.** En un indicador, `0` afirma un valor; `NULL` dice que no aplica. Las agregaciones ignoran los nulos: `AVG` sobre 15 filas con 5 nulos promedia 10.

### En hoja de cálculo

**`SI.ERROR` esconde errores reales.** Atrapa `#¡REF!` y `#¡VALOR!` igual que `#N/D`. En búsquedas usar `SI.ND`.

**Referencias sin `$` al arrastrar.** El rango se desplaza y la fórmula consulta celdas vacías o equivocadas, sin error.

**El número de columna de `BUSCARV`.** Si alguien inserta una columna, el índice sigue apuntando a la posición vieja y devuelve otro dato.

**Comodines sobre números.** `"*4135*"` no coincide con el número `4135`: los comodines solo operan sobre texto.

**Dos criterios de fecha con el mismo operador.** `>=` en los dos extremos colapsa el rango a un solo lado.

**Espacios invisibles y mayúsculas.** `"Cliente "` y `"Cliente"` son dos clientes distintos para cualquier cruce.

---

## 5. Antes de entregar un reporte

1. **Contar los requisitos del enunciado contra las cláusulas de la consulta.** Cada cosa que pide cae en una: columnas → `SELECT`, filtro → `WHERE`, agrupación → `GROUP BY`, orden → `ORDER BY`, límite → `LIMIT`.
2. **Comprobar el grano.** ¿Cuántas filas debería devolver? Una por factura, una por cliente, una por mes.
3. **Detectar fan-out.** `COUNT(*)` contra `COUNT(DISTINCT llave)`.
4. **Cuadrar contra el origen.** El total del reporte debe coincidir con la suma directa de la tabla base.
5. **Mirar la columna completa.** Si todos los valores salen iguales, probablemente se está midiendo la variable equivocada. Si uno se repite idéntico en muchas filas, probablemente pertenece a otra tabla.
6. **Revisar los casos límite.** Negativos, ceros, nulos, el primer registro, el último.
7. **Terminar con un número.** "Subió" no es un hallazgo; "subió 4,6 millones, un 39%" sí.

---

## 6. Para medir una diferencia

Cuando un total no cuadra con lo esperado:

- **Comparar contra la misma población.** Restar el total de 15 facturas contra el de 6 no mide nada.
- **Verificar la magnitud antes de investigar el origen.** Una diferencia mal calculada manda a buscar un problema que no existe.
- **Dos sistemas que dan cifras distintas rara vez tienen uno equivocado.** Normalmente uno aplica una regla de negocio que el otro no. El trabajo es encontrar la regla y cuantificar su efecto.
