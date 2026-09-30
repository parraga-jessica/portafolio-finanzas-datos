-- ============================================================
-- 02 · Maestro de clientes y abonos recibidos
--
-- Nota: el maestro NO contiene a Ferreteria Central, y la tabla
-- de pagos incluye un abono contra una factura inexistente.
-- Ambos casos son deliberados: son los hallazgos que los
-- controles de calidad deben detectar.
-- ============================================================

DROP TABLE IF EXISTS pagos;
DROP TABLE IF EXISTS clientes;

-- ------------------------------------------------------------
-- Maestro comercial
-- ------------------------------------------------------------
CREATE TABLE clientes (
    nombre          TEXT,
    nit             TEXT,
    ciudad          TEXT,
    sector          TEXT,
    cupo_aprobado   NUMERIC,
    vendedor        TEXT
);

INSERT INTO clientes VALUES
('Panaderia El Trigal',   '900123456','Bogota',   'Alimentos', 5000000,'Laura Gomez'),
('Distribuciones Munoz',  '900234567','Medellin', 'Mayorista', 8000000,'Carlos Ruiz'),
('Almacenes Jose Leon',   '900345678','Bogota',   'Retail',    4000000,'Laura Gomez'),
('Cafeteria La Esquina',  '900456789','Cali',     'Alimentos', 3000000,'Ana Torres'),
('Comercializadora Pena', '900567890','Medellin', 'Mayorista', 6000000,'Carlos Ruiz');

-- ------------------------------------------------------------
-- Abonos. Una factura puede tener varios: de ahí el riesgo
-- de fan-out al cruzar con cartera.
-- ------------------------------------------------------------
CREATE TABLE pagos (
    id_pago      INTEGER,
    factura      TEXT,
    fecha_pago   DATE,
    valor_pago   NUMERIC,
    medio        TEXT
);

INSERT INTO pagos VALUES
(1,  'FV-1001','2026-08-10',  400000,'Transferencia'),
(2,  'FV-1001','2026-09-05',  300000,'Transferencia'),
(3,  'FV-1001','2026-09-20',  200000,'Efectivo'),
(4,  'FV-1003','2026-09-01',  800000,'Transferencia'),
(5,  'FV-1003','2026-09-18',  500000,'Cheque'),
(6,  'FV-1005','2026-09-15',  900000,'Transferencia'),
(7,  'FV-1008','2026-09-10', 1000000,'Transferencia'),
(8,  'FV-1011','2026-09-12',  760000,'Efectivo'),
(9,  'FV-1013','2026-09-25',  500000,'Transferencia'),
(10, 'FV-8888','2026-09-14',  350000,'Transferencia');

SELECT 'clientes' AS tabla, COUNT(*) FROM clientes
UNION ALL
SELECT 'pagos', COUNT(*) FROM pagos;
