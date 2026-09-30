-- ============================================================
-- 03 · Política de cartera, parametrizada
--
-- Los tramos y los porcentajes de provisión NO viven dentro de
-- las consultas. Cambiar la política = editar estas cinco filas.
--
-- Los límites son un contrato entre filas vecinas: si se mueve
-- el inicio de un tramo, hay que mover el fin del anterior.
-- Un solape no produce error: duplica filas e infla los totales.
-- El control 5.3 del script 04 lo detecta.
-- ============================================================

DROP TABLE IF EXISTS rangos_mora;

CREATE TABLE rangos_mora (
    tramo          TEXT,
    orden          INTEGER,     -- orden de presentación del reporte
    dia_desde      INTEGER,
    dia_hasta      INTEGER,
    pct_provision  NUMERIC
);

INSERT INTO rangos_mora VALUES
('No vencida',  1,  -99999,    -1, 0.00),
('Al dia',      2,       0,     0, 0.00),
('1 a 30',      3,       1,    30, 0.05),
('31 a 60',     4,      31,    60, 0.20),
('Mas de 60',   5,      61, 99999, 0.50);

SELECT * FROM rangos_mora ORDER BY orden;
