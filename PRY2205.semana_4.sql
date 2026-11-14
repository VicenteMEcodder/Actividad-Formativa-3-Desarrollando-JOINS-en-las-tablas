
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.';
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

/*Listado de trabajadores*/
SELECT
    UPPER(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS "Nombre Completo Trabajador",
    TO_CHAR(t.numrut, 'FM999G999G999') || '-' || t.dvrut AS "RUT Trabajador",
    UPPER(tt.desc_categoria) AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador",
    TO_CHAR(ROUND(t.sueldo_base), 'FM$999G999G999') AS "Sueldo Base"
FROM trabajador t
JOIN tipo_trabajador tt
    ON t.id_categoria_t = tt.id_categoria
JOIN comuna_ciudad cc
    ON t.id_ciudad = cc.id_ciudad
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY cc.nombre_ciudad DESC,
         t.sueldo_base ASC;

/*Listado de cajeros*/
SELECT
    TO_CHAR(t.numrut, 'FM999G999G999') || '-' || t.dvrut AS "RUT Trabajador",
    INITCAP(t.nombre) || ' ' || t.appaterno AS "Nombre Trabajador",
    COUNT(tk.nro_ticket) AS "Total Tickets",
    TO_CHAR(ROUND(SUM(tk.monto_ticket)), 'FM$999G999G999') AS "Total Vendido",
    TO_CHAR(ROUND(SUM(ct.valor_comision)), 'FM$999G999G999') AS "Comisión Total",
    UPPER(tt.desc_categoria) AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
JOIN tipo_trabajador tt
    ON t.id_categoria_t = tt.id_categoria
JOIN comuna_ciudad cc
    ON t.id_ciudad = cc.id_ciudad
JOIN tickets_concierto tk
    ON t.numrut = tk.numrut_t
JOIN comisiones_ticket ct
    ON tk.nro_ticket = ct.nro_ticket
WHERE UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY t.numrut,
         t.dvrut,
         t.nombre,
         t.appaterno,
         tt.desc_categoria,
         cc.nombre_ciudad
HAVING SUM(tk.monto_ticket) > 50000
ORDER BY SUM(tk.monto_ticket) DESC;

/*Listado de beneficiarios*/
SELECT
    ROW_NUMBER() OVER (ORDER BY t.numrut) AS "Nº",
    TO_CHAR(t.numrut, 'FM999G999G999') || ' ' ||
    INITCAP(t.nombre) || ' ' || INITCAP(t.appaterno) AS "Trabajador",
    EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing) AS "Años Antigüedad",
    COUNT(af.numrut_carga) AS "Nom. Cargos Familiares",
    INITCAP(i.nombre_isapre) AS "Nombre Isapre",
    TO_CHAR(ROUND(t.sueldo_base), 'FM$999G999G999') AS "Fonasa Base",
    CASE
        WHEN UPPER(i.nombre_isapre) = 'FONASA'
        THEN TO_CHAR(ROUND(t.sueldo_base * 0.01), 'FM$999G999G999')
    END AS "Fonasa Bonos",
    TO_CHAR(
        CASE
            WHEN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing) <= 10
            THEN ROUND(t.sueldo_base * 0.10)
            ELSE ROUND(t.sueldo_base * 0.15)
        END,
        'FM$999G999G999'
    ) AS "Bono Asignado",
    INITCAP(a.nombre_afp) AS "Nombre AFP",
    UPPER(ec.desc_estcivil) AS "Estado Civil"
FROM trabajador t
JOIN isapre i
    ON t.cod_isapre = i.cod_isapre
JOIN afp a
    ON t.cod_afp = a.cod_afp
JOIN est_civil e
    ON t.numrut = e.numrut_t
   AND (e.fecter_estcivil IS NULL OR e.fecter_estcivil > SYSDATE)
JOIN estado_civil ec
    ON e.id_estcivil_est = ec.id_estcivil
LEFT JOIN asignacion_familiar af
    ON t.numrut = af.numrut_t
GROUP BY t.numrut,
         t.dvrut,
         t.nombre,
         t.appaterno,
         t.fecing,
         t.sueldo_base,
         i.nombre_isapre,
         a.nombre_afp,
         ec.desc_estcivil
ORDER BY t.numrut ASC;