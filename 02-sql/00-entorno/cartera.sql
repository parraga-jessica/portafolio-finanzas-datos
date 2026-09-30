-- ============================================================
-- Tabla de cartera de ANDINA al corte 30/09/2026
-- Crea la tabla y carga las 15 facturas.
-- Ejecutar completo con Alt + X sobre la base `andina`.
-- ============================================================

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

INSERT INTO cartera VALUES
('FV-1001','Panaderia El Trigal',   '2026-06-15','2026-07-15', 1250000,  77,'CRITICA'),
('FV-1002','Panaderia El Trigal',   '2026-08-03','2026-09-02',  890000,  28,'VENCIDA 30'),
('FV-1003','Distribuciones Munoz',  '2026-07-05','2026-08-04', 2100000,  57,'VENCIDA 60'),
('FV-1004','Almacenes Jose Leon',   '2026-05-08','2026-06-07',  450000, 115,'CRITICA'),
('FV-1005','Distribuciones Munoz',  '2026-08-10','2026-09-09', 1780000,  21,'VENCIDA 30'),
('FV-1006','Cafeteria La Esquina',  '2026-08-12','2026-09-11', 3450000,  19,'VENCIDA 30'),
('FV-1007','Panaderia El Trigal',   '2026-08-15','2026-09-14',  670000,  16,'VENCIDA 30'),
('FV-1008','Comercializadora Pena', '2026-07-18','2026-08-17', 2340000,  44,'VENCIDA 60'),
('FV-1009','Almacenes Jose Leon',   '2026-08-20','2026-09-19', 1120000,  11,'VENCIDA 30'),
('FV-1010','Cafeteria La Esquina',  '2026-08-22','2026-09-21',  980000,   9,'VENCIDA 30'),
('FV-1011','Distribuciones Munoz',  '2026-07-25','2026-08-24', 1560000,  37,'VENCIDA 60'),
('FV-1012','Comercializadora Pena', '2026-08-28','2026-09-27', -450000,   3,'NOTA DE CREDITO'),
('FV-1013','Panaderia El Trigal',   '2026-08-30','2026-09-29', 2890000,   1,'VENCIDA 30'),
('FV-1014','Almacenes Jose Leon',   '2026-08-31','2026-09-30', 1340000,   0,'AL DIA'),
('FV-1015','Ferreteria Central',    '2026-09-02','2026-10-02', 1700000,  -2,'NO VENCIDA');

-- Verificación: debe devolver 15
SELECT COUNT(*) FROM cartera;
