-- =====================================================================
-- 1. AMPLIACIÓN DE DATOS EN EL DW (Necesario para K-Means y pruebas)
-- =====================================================================
USE medired_dw;

INSERT INTO Dim_Paciente (Documento_Hash, Nombre_Paciente, Edad, Rango_Edad, Genero, Ciudad_Residencia) VALUES
('d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2', 'Andrés Morales', 45, '18-59', 'M', 'Soacha'),
('e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3', 'Lucía Fernández', 72, '60+', 'F', 'Bosa'),
('f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4', 'Diego Castro', 19, '18-59', 'M', 'Soacha'),
('a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5', 'Sofía Vargas', 34, '18-59', 'F', 'Bosa'),
('b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6', 'Jorge Mendoza', 68, '60+', 'M', 'Soacha'),
('c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7', 'Valentina Ruiz', 8, '0-17', 'F', 'Bosa'),
('d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8', 'Camilo Herrera', 52, '18-59', 'M', 'Soacha'),
('e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9', 'Patricia Rojas', 61, '60+', 'F', 'Bosa'),
('f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0', 'Mateo Ortiz', 24, '18-59', 'M', 'Soacha'),
('a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1', 'Camila Díaz', 39, '18-59', 'F', 'Bosa'),
('b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2', 'Héctor Pinzón', 75, '60+', 'M', 'Soacha'),
('c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3', 'Daniela Silva', 15, '0-17', 'F', 'Bosa');

INSERT INTO Fact_Atenciones (ID_Paciente, ID_Medico, ID_Sede, ID_Diagnostico, ID_Tiempo, Costo_Atencion, Tiempo_Espera_Min, Cantidad_Medicamentos, Estado_Atencion) VALUES
(4, 1, 1, 2, 20261108, 75000.00, 30, 4, 'Completada'),
(5, 3, 2, 3, 20261108, 120000.00, 50, 6, 'Completada'),
(6, 1, 1, 1, 20261109, 40000.00, 15, 1, 'Completada'),
(7, 1, 2, 1, 20261109, 48000.00, 20, 2, 'Cancelada'),
(8, 3, 1, 2, 20261108, 115000.00, 45, 5, 'Completada'),
(9, 2, 2, 1, 20261109, 52000.00, 18, 2, 'Completada'),
(10, 1, 1, 2, 20261108, 82000.00, 35, 3, 'Completada'),
(11, 3, 2, 3, 20261109, 110000.00, 42, 5, 'Completada'),
(12, 1, 1, 1, 20261108, 42000.00, 12, 1, 'Inasistencia'),
(13, 1, 2, 2, 20261109, 68000.00, 28, 3, 'Completada'),
(14, 3, 1, 3, 20261108, 135000.00, 55, 7, 'Completada'),
(15, 2, 2, 1, 20261109, 47000.00, 22, 2, 'Completada');

-- =====================================================================
-- 2. FRAGMENTACIÓN HORIZONTAL (Distribuida en 2 Nodos + PARTITION BY)
-- =====================================================================

-- Fragmento Horizontal 1: Sede Soacha (Alojado en Nodo A: medired_dw)
CREATE OR REPLACE TABLE medired_dw.Frag_H_Atenciones_Soacha AS
SELECT * FROM medired_dw.Fact_Atenciones
WHERE ID_Sede = 1;

-- Fragmento Horizontal 2: Sede Bosa (Alojado en Nodo B: medired_nodo_bosa)
CREATE OR REPLACE TABLE medired_nodo_bosa.Frag_H_Atenciones_Bosa AS
SELECT * FROM medired_dw.Fact_Atenciones
WHERE ID_Sede = 2;

-- Particionamiento nativo en MariaDB (PARTITION BY LIST) sobre copia histórica
CREATE TABLE IF NOT EXISTS medired_dw.Fact_Atenciones_Particionada (
    ID_Atencion INT NOT NULL,
    ID_Paciente INT NOT NULL,
    ID_Sede INT NOT NULL,
    Costo_Atencion DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (ID_Atencion, ID_Sede)
)
PARTITION BY LIST (ID_Sede) (
    PARTITION p_soacha VALUES IN (1),
    PARTITION p_bosa VALUES IN (2)
);

INSERT IGNORE INTO medired_dw.Fact_Atenciones_Particionada (ID_Atencion, ID_Paciente, ID_Sede, Costo_Atencion)
SELECT ID_Atencion, ID_Paciente, ID_Sede, Costo_Atencion FROM medired_dw.Fact_Atenciones;

-- =====================================================================
-- 3. FRAGMENTACIÓN VERTICAL (Separación de columnas en 2 Nodos)
-- =====================================================================

-- Fragmento Vertical 1: Datos de identificación pública (Nodo A: medired_dw)
CREATE OR REPLACE TABLE medired_dw.Frag_V_Paciente_Publico AS
SELECT ID_Paciente, Nombre_Paciente, Ciudad_Residencia
FROM medired_dw.Dim_Paciente;

-- Fragmento Vertical 2: Datos clínicos/demográficos sensibles (Nodo B: medired_nodo_bosa)
CREATE OR REPLACE TABLE medired_nodo_bosa.Frag_V_Paciente_Sensible AS
SELECT ID_Paciente, Documento_Hash, Edad, Rango_Edad, Genero
FROM medired_dw.Dim_Paciente;

USE medired_dw;

-- =====================================================================
-- PRUEBA 1: RECONSTRUCCIÓN HORIZONTAL (UNION ALL) Y CONTEO SIN PÉRDIDA
-- =====================================================================
SELECT 'Tabla Original (Fact_Atenciones)' AS Origen, COUNT(*) AS Total_Filas
FROM medired_dw.Fact_Atenciones
UNION ALL
SELECT 'Reconstrucción Horizontal (Nodo A + Nodo B)' AS Origen, COUNT(*) AS Total_Filas
FROM (
    SELECT * FROM medired_dw.Frag_H_Atenciones_Soacha
    UNION ALL
    SELECT * FROM medired_nodo_bosa.Frag_H_Atenciones_Bosa
) AS Reconstruccion_H;

-- =====================================================================
-- PRUEBA 2: RECONSTRUCCIÓN VERTICAL (INNER JOIN) Y CONTEO SIN PÉRDIDA
-- =====================================================================
SELECT 'Tabla Original (Dim_Paciente)' AS Origen, COUNT(*) AS Total_Filas
FROM medired_dw.Dim_Paciente
UNION ALL
SELECT 'Reconstrucción Vertical (JOIN Nodo A + Nodo B)' AS Origen, COUNT(*) AS Total_Filas
FROM medired_dw.Frag_V_Paciente_Publico pub
INNER JOIN medired_nodo_bosa.Frag_V_Paciente_Sensible sen
        ON pub.ID_Paciente = sen.ID_Paciente;
