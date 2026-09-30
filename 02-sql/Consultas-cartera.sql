--1. "¿Cuánta plata nos deben en total?"
select sum(valor) as total_deuda
from cartera;

--2. "¿Cuántas facturas tenemos vencidas?"
select COUNT (*) as FACTURAS_VENCIDAS
from cartera 
where upper(estado) not in ('AL DIA','NOTA DE CREDITO','NO VENCIDA');

--3. "¿Cuál es la factura más atrasada que tenemos?"
select factura, dias_mora, estado 
from cartera 
order by dias_mora desc
limit 1;

--4. "Pásame la lista de clientes con los que trabajamos."
select distinct cliente 
from cartera;

5. "¿Cuánto nos debe Distribuciones Muñoz?"
select SUM(valor) as TOTAL_MUNOZ
from cartera 
where cliente ilike '%distribuciones munoz%';

--6. "Muéstrame las facturas de más de dos millones que además lleven más de 30 días vencidas."
select factura, cliente, valor, DIAS_MORA, estado
from cartera 
where DIAS_MORA > 30 and valor > 2000000;


--7. "Quiero ver todo lo que está crítico o vencido a 60." — usa IN
select FACTURA, CLIENTE, VALOR, ESTADO
from cartera 
where ESTADO in ('CRITICA','VENCIDA 60');

8. --"¿Qué facturamos en agosto?" — por fecha de emisión
select FACTURA, CLIENTE, FECHA_EMISION
from CARTERA
where FECHA_EMISION BETWEEN '2026-08-01' and '2026-08-31';

--9. "¿Qué clientes tenemos cuyo nombre empiece por C?"
select distinct CLIENTE
from cartera 
where CLIENTE ilike 'C%';

--10. "Las tres facturas que más provisión generan al 20%, sin contar notas crédito."
select factura, estado, valor * 0.20 AS provision
from cartera
where UPPER (estado) not in ('NOTA DE CREDITO')
order by VALOR DESC
limit 3;


-------------------



--por facturas 
select cliente,
count(*) as facturas,
sum (valor) as total,
max(dias_mora) as peor_mora
from cartera 
group by cliente 
order by total desc;


--por estados
select estado,
count(*) as facturas,
sum (valor) as total,
max(dias_mora) as peor_mora
from cartera 
group by estado  
order by total desc;


--
SELECT COUNT(*) FROM cartera;

SELECT COUNT(DISTINCT cliente) FROM cartera;


-- con mas de 2
SELECT 
    cliente, 
    COUNT(*) AS total_facturas, 
    SUM(valor) AS saldo_total
FROM cartera
GROUP BY cliente
HAVING COUNT(*) > 2;

--- saldo superior a 5mill
SELECT  estado, SUM(valor) AS saldo_total 
FROM cartera 
GROUP BY estado
HAVING SUM(valor) > 5000000;


-- mora >50 mostrar clientes y mora
SELECT 
    cliente,  
    max(dias_mora) AS peor_mora
FROM cartera 
GROUP BY cliente 
HAVING max(dias_mora) > 50;

-- clientes sin notas de credito
select cliente, COUNT(*) as TOTAL_FACTURA
from cartera 
where estado <>'NOTA DE CREDITO'
group by cliente
having count(*) > 2;


-- resumen cliente y estado
select  cliente, estado,
SUM(VALOR) as TOTAL, count(*) facturas
from CARTERA 
group by CLIENTE,ESTADO
order by cliente, estado;

--rollup
select coalesce(estado,'total general') as estado, coalesce(cliente,'subtotal') as cliente,
sum(valor) as total
from cartera 
group by rollup (estado, cliente)
order by (estado, cliente);


-------INNER JOIN-------------------

SELECT
    c.factura,
    c.cliente,
    c.valor,
    cl.nit,
    cl.ciudad,
    cl.vendedor
FROM cartera 
INNER JOIN clientes cl ON c.cliente = cl.nombre;
