-- ============================================================
-- 04 · AGING DE CARTERA · ANDINA S.A.S.
--      Corte: 30/09/2026
--
-- Ejecutar antes: 01-cartera.sql · 02-clientes-pagos.sql ·
--                 03-rangos-mora.sql
--
-- Cada bloque es una consulta independiente: seleccionar
-- y ejecutar por separado.
-- ============================================================


-- ============================================================
-- 1. LA VISTA
--    Concentra toda la lógica: agregación de pagos, asignación
--    de tramo, provisión y banderas de integridad.
--    Se escribe una vez; los reportes de abajo solo la consultan.
-- ============================================================

CREATE OR REPLACE VIEW v_cartera_detalle AS
WITH pagos_por_factura AS (
    -- Colapsa los abonos a una fila por factura.
    -- Sin esto, el JOIN con `pagos` duplicaría las facturas
    -- con varios abonos e inflaría todos los totales (fan-out).
    SELECT
        factura,
        SUM(valor_pago) AS total_pagado,
        COUNT(*)        AS num_abonos
    FROM pagos
    GROUP BY factura
)
SELECT
    c.factura,
    c.cliente,
    c.fecha_emision,
    c.fecha_vencimiento,
    c.dias_mora,
    c.estado,
    r.tramo,
    r.orden                              AS orden_tramo,
    cl.ciudad,
    cl.vendedor,
    cl.cupo_aprobado,
    c.valor,
    COALESCE(p.total_pagado, 0)          AS pagado,
    COALESCE(p.num_abonos, 0)            AS abonos,
    c.valor - COALESCE(p.total_pagado,0) AS saldo,

    -- Las notas crédito no se provisionan: no son cartera en riesgo,
    -- son valores que la empresa adeuda al cliente.
    CASE WHEN c.estado = 'NOTA DE CREDITO' THEN 0
         ELSE c.valor * r.pct_provision
    END                                  AS provision,

    -- NULL, no cero, cuando el indicador no aplica.
    -- Un 0% diría "no se ha cobrado nada"; NULL dice "no aplica".
    CASE WHEN c.valor <= 0 THEN NULL
         ELSE ROUND(COALESCE(p.total_pagado,0) * 100.0 / c.valor, 1)
    END                                  AS pct_cobrado,

    -- Bandera de auditoría visible en el propio reporte
    CASE WHEN cl.nombre IS NULL THEN 'ALERTA: cliente no registrado'
         ELSE 'OK'
    END                                  AS estado_integridad

FROM cartera c
-- JOIN por rango: cada factura cae en el tramo que le corresponde
-- según sus días de mora. Equivale a un BUSCARV aproximado,
-- pero sin exigir que la tabla esté ordenada.
LEFT JOIN rangos_mora       r  ON c.dias_mora BETWEEN r.dia_desde AND r.dia_hasta
LEFT JOIN clientes          cl ON c.cliente  = cl.nombre
LEFT JOIN pagos_por_factura p  ON c.factura  = p.factura;
-- Los tres JOIN son LEFT a propósito: en un reporte de cartera,
-- perder una fila es peor que mostrarla incompleta.


-- ============================================================
-- 2. DETALLE POR FACTURA
--    Lo más crítico arriba; dentro de cada tramo, lo más grande.
-- ============================================================

SELECT *
FROM v_cartera_detalle
ORDER BY orden_tramo DESC, saldo DESC;


-- ============================================================
-- 3. AGING POR CLIENTE
--    Un cliente por fila, un tramo por columna.
--    Es el reporte que se entrega a gerencia.
-- ============================================================

SELECT
    cliente,
    COUNT(*)                                                  AS facturas,
    SUM(CASE WHEN tramo = 'No vencida' THEN valor ELSE 0 END) AS no_vencida,
    SUM(CASE WHEN tramo = 'Al dia'     THEN valor ELSE 0 END) AS al_dia,
    SUM(CASE WHEN tramo = '1 a 30'     THEN valor ELSE 0 END) AS d1_30,
    SUM(CASE WHEN tramo = '31 a 60'    THEN valor ELSE 0 END) AS d31_60,
    SUM(CASE WHEN tramo = 'Mas de 60'  THEN valor ELSE 0 END) AS mas_60,
    SUM(valor)                                                AS total_cartera,
    SUM(saldo)                                                AS saldo_pendiente,
    SUM(provision)                                            AS provision
FROM v_cartera_detalle
GROUP BY cliente
ORDER BY provision DESC;


-- ============================================================
-- 4. RESUMEN POR TRAMO
--    La foto que se mira primero: dónde está concentrada la plata.
-- ============================================================

SELECT
    tramo,
    COUNT(*)       AS facturas,
    SUM(valor)     AS cartera,
    SUM(saldo)     AS saldo_pendiente,
    SUM(provision) AS provision
FROM v_cartera_detalle
GROUP BY tramo, orden_tramo
ORDER BY orden_tramo;


-- ============================================================
-- 5. CONTROLES DE CALIDAD
--    Se ejecutan en cada cierre. En una cartera sana devuelven
--    cero filas; aquí 5.1 y 5.2 devuelven los hallazgos.
-- ============================================================

-- 5.1 · Facturas cuyo cliente no está en el maestro
--      Se usa anti-join y no NOT IN: si el maestro tuviera un
--      nombre nulo, NOT IN devolvería cero filas siempre.
SELECT c.factura, c.cliente, c.valor
FROM cartera c
LEFT JOIN clientes cl ON c.cliente = cl.nombre
WHERE cl.nombre IS NULL;

-- 5.2 · Pagos que no corresponden a ninguna factura
SELECT p.id_pago, p.factura, p.fecha_pago, p.valor_pago
FROM pagos p
LEFT JOIN cartera c ON p.factura = c.factura
WHERE c.factura IS NULL;

-- 5.3 · Tramos de mora solapados entre sí
--      Un solape duplica filas e infla los totales sin dar error.
SELECT a.tramo AS tramo_a, b.tramo AS tramo_b
FROM rangos_mora a
JOIN rangos_mora b
  ON a.tramo <> b.tramo
 AND a.dia_desde <= b.dia_hasta
 AND b.dia_desde <= a.dia_hasta;

-- 5.4 · Facturas que no cayeron en ningún tramo
--      Indica un hueco en la tabla de política.
SELECT factura, dias_mora
FROM v_cartera_detalle
WHERE tramo IS NULL;

-- 5.5 · Facturas con abonos superiores a su valor
SELECT factura, cliente, valor, pagado, saldo
FROM v_cartera_detalle
WHERE saldo < 0 AND valor > 0;


-- ============================================================
-- 6. CUADRE
--    Filas y facturas deben coincidir: si difieren, hay fan-out.
--    El total debe coincidir con la suma directa del origen.
-- ============================================================

SELECT
    COUNT(*)                AS filas,
    COUNT(DISTINCT factura) AS facturas,
    SUM(valor)              AS total_cartera,
    SUM(pagado)             AS total_pagado,
    SUM(saldo)              AS total_saldo,
    SUM(provision)          AS total_provision
FROM v_cartera_detalle;

-- Control independiente, sin pasar por la vista
SELECT SUM(valor) AS control_cartera FROM cartera;
