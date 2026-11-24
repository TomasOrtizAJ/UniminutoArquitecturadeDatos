USE medired_dw;

-- =====================================================================
-- 1. TABLA DE REGISTRO DE VALIDACIONES DE CALIDAD (Ítem 33)
-- =====================================================================
CREATE TABLE IF NOT EXISTS Auditoria_Calidad (
    ID_Auditoria INT PRIMARY KEY AUTO_INCREMENT,
    Fecha_Ejecucion DATETIME DEFAULT CURRENT_TIMESTAMP,
    Tabla_Evaluada VARCHAR(50) NOT NULL,
    Regla_Calidad VARCHAR(120) NOT NULL,
    Registros_Evaluados INT NOT NULL,
    Registros_Invalidos INT NOT NULL,
    Estado_Validacion VARCHAR(20) NOT NULL,
    Detalle_Observacion VARCHAR(200)
);

TRUNCATE TABLE Auditoria_Calidad;

-- =====================================================================
-- 2. EJECUCIÓN DE 6 REGLAS DE CALIDAD AUTOMATIZADAS (Ítem 32)
-- =====================================================================

-- Regla 1: Integridad de edad biológica (0 a 115 años)
INSERT INTO Auditoria_Calidad (Tabla_Evaluada, Regla_Calidad, Registros_Evaluados, Registros_Invalidos, Estado_Validacion, Detalle_Observacion)
SELECT 
    'Dim_Paciente',
    'R1: Rango de edad válido (0 <= Edad <= 115)',
    COUNT(*),
    SUM(CASE WHEN Edad < 0 OR Edad > 115 OR Edad IS NULL THEN 1 ELSE 0 END),
    IF(SUM(CASE WHEN Edad < 0 OR Edad > 115 OR Edad IS NULL THEN 1 ELSE 0 END) = 0, 'APROBADO', 'ALERTA'),
    'Verifica ausencia de edades negativas o irreales'
FROM Dim_Paciente;

-- Regla 2: Longitud y formato Hash SHA-256 en Documento_Hash (64 caracteres)
INSERT INTO Auditoria_Calidad (Tabla_Evaluada, Regla_Calidad, Registros_Evaluados, Registros_Invalidos, Estado_Validacion, Detalle_Observacion)
SELECT 
    'Dim_Paciente',
    'R2: Documento seudonimizado con SHA-256 (64 chars)',
    COUNT(*),
    SUM(CASE WHEN CHAR_LENGTH(Documento_Hash) <> 64 THEN 1 ELSE 0 END),
    IF(SUM(CASE WHEN CHAR_LENGTH(Documento_Hash) <> 64 THEN 1 ELSE 0 END) = 0, 'APROBADO', 'ALERTA'),
    'Garantiza cumplimiento de anonimización Ley 1581'
FROM Dim_Paciente;

-- Regla 3: Costos de atención estrictamente positivos (> 0)
INSERT INTO Auditoria_Calidad (Tabla_Evaluada, Regla_Calidad, Registros_Evaluados, Registros_Invalidos, Estado_Validacion, Detalle_Observacion)
SELECT 
    'Fact_Atenciones',
    'R3: Costo_Atencion mayor a cero (> 0 COP)',
    COUNT(*),
    SUM(CASE WHEN Costo_Atencion <= 0 OR Costo_Atencion IS NULL THEN 1 ELSE 0 END),
    IF(SUM(CASE WHEN Costo_Atencion <= 0 OR Costo_Atencion IS NULL THEN 1 ELSE 0 END) = 0, 'APROBADO', 'ALERTA'),
    'Evita registros financieros en cero o negativos'
FROM Fact_Atenciones;

-- Regla 4: Tiempos de espera no negativos (0 a 480 minutos)
INSERT INTO Auditoria_Calidad (Tabla_Evaluada, Regla_Calidad, Registros_Evaluados, Registros_Invalidos, Estado_Validacion, Detalle_Observacion)
SELECT 
    'Fact_Atenciones',
    'R4: Tiempo_Espera_Min en rango operativo (0 - 480 min)',
    COUNT(*),
    SUM(CASE WHEN Tiempo_Espera_Min < 0 OR Tiempo_Espera_Min > 480 THEN 1 ELSE 0 END),
    IF(SUM(CASE WHEN Tiempo_Espera_Min < 0 OR Tiempo_Espera_Min > 480 THEN 1 ELSE 0 END) = 0, 'APROBADO', 'ALERTA'),
    'Controla anomalías en tiempos de admisión'
FROM Fact_Atenciones;

-- Regla 5: Dominio controlado de Estado_Atencion
INSERT INTO Auditoria_Calidad (Tabla_Evaluada, Regla_Calidad, Registros_Evaluados, Registros_Invalidos, Estado_Validacion, Detalle_Observacion)
SELECT 
    'Fact_Atenciones',
    'R5: Estado_Atencion dentro del catálogo permitido',
    COUNT(*),
    SUM(CASE WHEN Estado_Atencion NOT IN ('Completada', 'Cancelada', 'Inasistencia') THEN 1 ELSE 0 END),
    IF(SUM(CASE WHEN Estado_Atencion NOT IN ('Completada', 'Cancelada', 'Inasistencia') THEN 1 ELSE 0 END) = 0, 'APROBADO', 'ALERTA'),
    'Valida estandarización categórica'
FROM Fact_Atenciones;

-- Regla 6: Unicidad de pacientes (sin documentos hash duplicados)
INSERT INTO Auditoria_Calidad (Tabla_Evaluada, Regla_Calidad, Registros_Evaluados, Registros_Invalidos, Estado_Validacion, Detalle_Observacion)
SELECT 
    'Dim_Paciente',
    'R6: Unicidad de Documento_Hash (sin duplicados)',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT Documento_Hash),
    IF(COUNT(*) - COUNT(DISTINCT Documento_Hash) = 0, 'APROBADO', 'ALERTA'),
    'Previene duplicación de historias clínicas'
FROM Dim_Paciente;

-- =====================================================================
-- 3. PROTECCIÓN DE DATOS CON SALT Y LEY 1581 DE 2012 (Ítems 37 y 38)
-- =====================================================================

-- Reforzamos la seudonimización aplicando un SALT institucional secreto
UPDATE Dim_Paciente
SET Documento_Hash = SHA2(CONCAT(Documento_Hash, 'MediRed_Salt_Secreta_2026!'), 256)
WHERE ID_Paciente > 0;

-- Vista enmascarada para analistas (oculta nombres reales y muestra solo iniciales + hash)
CREATE OR REPLACE VIEW Vw_Pacientes_Anonimizados AS
SELECT 
    ID_Paciente,
    LEFT(Documento_Hash, 12) AS Id_Seudonimo,
    CONCAT(LEFT(Nombre_Paciente, 2), '****') AS Nombre_Enmascarado,
    Edad,
    Rango_Edad,
    Genero,
    Ciudad_Residencia
FROM Dim_Paciente;
