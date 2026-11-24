USE medired_dw;

-- =====================================================================
-- KPI 1 (PIVOTE SQL): Costo Total y Promedio por Sede y Estado de Atención
-- =====================================================================
SELECT 
    s.Nombre_Sede AS Sede,
    COUNT(f.ID_Atencion) AS Total_Atenciones,
    SUM(CASE WHEN f.Estado_Atencion = 'Completada' THEN f.Costo_Atencion ELSE 0 END) AS Ingresos_Completadas_COP,
    SUM(CASE WHEN f.Estado_Atencion = 'Cancelada' THEN f.Costo_Atencion ELSE 0 END) AS Costo_Canceladas_COP,
    SUM(CASE WHEN f.Estado_Atencion = 'Inasistencia' THEN f.Costo_Atencion ELSE 0 END) AS Costo_Inasistencias_COP,
    ROUND(AVG(f.Costo_Atencion), 2) AS KPI1_Costo_Promedio_COP
FROM Fact_Atenciones f
INNER JOIN Dim_Sede s ON f.ID_Sede = s.ID_Sede
GROUP BY s.Nombre_Sede;

-- =====================================================================
-- KPI 2 (PIVOTE SQL): Tasa de Efectividad (Atendidas vs. Canceladas) por Sede
-- =====================================================================
SELECT 
    s.Nombre_Sede AS Sede,
    SUM(CASE WHEN f.Estado_Atencion = 'Completada' THEN 1 ELSE 0 END) AS Completadas,
    SUM(CASE WHEN f.Estado_Atencion = 'Cancelada' THEN 1 ELSE 0 END) AS Canceladas,
    SUM(CASE WHEN f.Estado_Atencion = 'Inasistencia' THEN 1 ELSE 0 END) AS Inasistencias,
    ROUND(
        (SUM(CASE WHEN f.Estado_Atencion = 'Completada' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2
    ) AS KPI2_Tasa_Efectividad_Pct
FROM Fact_Atenciones f
INNER JOIN Dim_Sede s ON f.ID_Sede = s.ID_Sede
GROUP BY s.Nombre_Sede;

-- =====================================================================
-- KPI 3 (PIVOTE SQL): Medicamentos Dispensados por Especialidad y Gravedad
-- =====================================================================
SELECT 
    m.Especialidad,
    SUM(CASE WHEN d.Categoria_Gravedad = 'Leve' THEN f.Cantidad_Medicamentos ELSE 0 END) AS Meds_Gravedad_Leve,
    SUM(CASE WHEN d.Categoria_Gravedad = 'Moderado' THEN f.Cantidad_Medicamentos ELSE 0 END) AS Meds_Gravedad_Moderada,
    SUM(CASE WHEN d.Categoria_Gravedad = 'Critico' THEN f.Cantidad_Medicamentos ELSE 0 END) AS Meds_Gravedad_Critica,
    SUM(f.Cantidad_Medicamentos) AS KPI3_Total_Medicamentos
FROM Fact_Atenciones f
INNER JOIN Dim_Medico m ON f.ID_Medico = m.ID_Medico
INNER JOIN Dim_Diagnostico d ON f.ID_Diagnostico = d.ID_Diagnostico
GROUP BY m.Especialidad;

-- =====================================================================
-- KPI 4 (PIVOTE SQL): Tiempo Medio de Espera (Min) por Rango de Edad y Sede
-- =====================================================================
SELECT 
    p.Rango_Edad,
    ROUND(AVG(CASE WHEN s.Nombre_Sede LIKE '%Soacha%' THEN f.Tiempo_Espera_Min END), 1) AS Espera_Promedio_Soacha_Min,
    ROUND(AVG(CASE WHEN s.Nombre_Sede LIKE '%Bosa%' THEN f.Tiempo_Espera_Min END), 1) AS Espera_Promedio_Bosa_Min,
    ROUND(AVG(f.Tiempo_Espera_Min), 1) AS KPI4_Espera_Global_Min
FROM Fact_Atenciones f
INNER JOIN Dim_Paciente p ON f.ID_Paciente = p.ID_Paciente
INNER JOIN Dim_Sede s ON f.ID_Sede = s.ID_Sede
GROUP BY p.Rango_Edad
ORDER BY p.Rango_Edad;
