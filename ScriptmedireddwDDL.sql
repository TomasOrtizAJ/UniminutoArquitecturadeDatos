-- ==========================================
-- 1. CREACIÓN DE BASES DE DATOS
-- ==========================================
CREATE DATABASE IF NOT EXISTS medired_staging;
CREATE DATABASE IF NOT EXISTS medired_dw;

USE medired_dw;

-- ==========================================
-- 2. TABLAS DE DIMENSIÓN
-- ==========================================

-- Dimensión Paciente
CREATE TABLE IF NOT EXISTS Dim_Paciente (
    ID_Paciente INT PRIMARY KEY AUTO_INCREMENT,
    Documento_Hash VARCHAR(64) NOT NULL, -- Seudonimizado para Ley 1581
    Nombre_Paciente VARCHAR(100) NOT NULL,
    Edad INT NOT NULL,
    Rango_Edad VARCHAR(20) NOT NULL, -- Ej: '0-17', '18-59', '60+'
    Genero CHAR(1) NOT NULL,
    Ciudad_Residencia VARCHAR(50) NOT NULL
);

-- Dimensión Médico
CREATE TABLE IF NOT EXISTS Dim_Medico (
    ID_Medico INT PRIMARY KEY AUTO_INCREMENT,
    Codigo_Registro VARCHAR(20) NOT NULL,
    Nombre_Medico VARCHAR(100) NOT NULL,
    Especialidad VARCHAR(50) NOT NULL,
    Estado_Licencia VARCHAR(20) DEFAULT 'Activo'
);

-- Dimensión Sede
CREATE TABLE IF NOT EXISTS Dim_Sede (
    ID_Sede INT PRIMARY KEY AUTO_INCREMENT,
    Nombre_Sede VARCHAR(50) NOT NULL, -- Ej: 'Sede Soacha', 'Sede Bosa'
    Ciudad VARCHAR(50) NOT NULL,
    Direccion VARCHAR(100) NOT NULL,
    Nodo_Servidor VARCHAR(20) NOT NULL -- Identificador de nodo ('NodoA', 'NodoB')
);

-- Dimensión Diagnóstico
CREATE TABLE IF NOT EXISTS Dim_Diagnostico (
    ID_Diagnostico INT PRIMARY KEY AUTO_INCREMENT,
    Codigo_CIE10 VARCHAR(10) NOT NULL,
    Descripcion_Diagnostico VARCHAR(150) NOT NULL,
    Categoria_Gravedad VARCHAR(20) NOT NULL -- Ej: 'Leve', 'Moderado', 'Critico'
);

-- Dimensión Tiempo
CREATE TABLE IF NOT EXISTS Dim_Tiempo (
    ID_Tiempo INT PRIMARY KEY, -- Formato AAAAMMDD (Ej: 20261109)
    Fecha DATE NOT NULL,
    Anio INT NOT NULL,
    Mes INT NOT NULL,
    Nombre_Mes VARCHAR(15) NOT NULL,
    Trimestre INT NOT NULL,
    Dia_Semana VARCHAR(15) NOT NULL
);

-- ==========================================
-- 3. TABLA DE HECHOS (FACT TABLE)
-- ==========================================

CREATE TABLE IF NOT EXISTS Fact_Atenciones (
    ID_Atencion INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Llaves Foráneas (FK) hacia Dimensiones
    ID_Paciente INT NOT NULL,
    ID_Medico INT NOT NULL,
    ID_Sede INT NOT NULL,
    ID_Diagnostico INT NOT NULL,
    ID_Tiempo INT NOT NULL,
    
    -- Métricas / Hechos
    Costo_Atencion DECIMAL(10, 2) NOT NULL,
    Tiempo_Espera_Min INT NOT NULL,
    Cantidad_Medicamentos INT DEFAULT 0,
    Estado_Atencion VARCHAR(20) NOT NULL, -- Ej: 'Completada', 'Cancelada', 'Inasistencia'
    
    -- Definición de Restricciones FK
    CONSTRAINT fk_fact_paciente FOREIGN KEY (ID_Paciente) REFERENCES Dim_Paciente(ID_Paciente),
    CONSTRAINT fk_fact_medico FOREIGN KEY (ID_Medico) REFERENCES Dim_Medico(ID_Medico),
    CONSTRAINT fk_fact_sede FOREIGN KEY (ID_Sede) REFERENCES Dim_Sede(ID_Sede),
    CONSTRAINT fk_fact_diagnostico FOREIGN KEY (ID_Diagnostico) REFERENCES Dim_Diagnostico(ID_Diagnostico),
    CONSTRAINT fk_fact_tiempo FOREIGN KEY (ID_Tiempo) REFERENCES Dim_Tiempo(ID_Tiempo)
);

-- ==========================================
-- 4. CARGA DE DATOS INICIALES
-- ==========================================

USE medired_dw;

-- Poblado Dim_Paciente
INSERT INTO Dim_Paciente (Documento_Hash, Nombre_Paciente, Edad, Rango_Edad, Genero, Ciudad_Residencia) VALUES
('a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'Juan Pérez', 28, '18-59', 'M', 'Soacha'),
('b3a8e0e1f9ab1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c', 'María Rodríguez', 65, '60+', 'F', 'Bosa'),
('c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8', 'Carlos Gómez', 12, '0-17', 'M', 'Soacha');

-- Poblado Dim_Medico
INSERT INTO Dim_Medico (Codigo_Registro, Nombre_Medico, Especialidad) VALUES
('MED-101', 'Dra. Ana Martínez', 'Medicina General'),
('MED-102', 'Dr. Roberto Silva', 'Pediatría'),
('MED-103', 'Dra. Elena Torres', 'Urgentología');

-- Poblado Dim_Sede
INSERT INTO Dim_Sede (Nombre_Sede, Ciudad, Direccion, Nodo_Servidor) VALUES
('Sede Soacha Centro', 'Soacha', 'Calle 13 # 7-10', 'NodoA'),
('Sede Bosa Estación', 'Bogotá', 'Carrera 80 # 58-20 Sur', 'NodoB');

-- Poblado Dim_Diagnostico
INSERT INTO Dim_Diagnostico (Codigo_CIE10, Descripcion_Diagnostico, Categoria_Gravedad) VALUES
('J00', 'Rinitis aguda / Resfriado común', 'Leve'),
('E11', 'Diabetes mellitus tipo 2', 'Moderado'),
('I10', 'Hipertensión esencial (primaria)', 'Moderado');

-- Poblado Dim_Tiempo
INSERT INTO Dim_Tiempo (ID_Tiempo, Fecha, Anio, Mes, Nombre_Mes, Trimestre, Dia_Semana) VALUES
(20261108, '2026-11-08', 2026, 11, 'Noviembre', 4, 'Domingo'),
(20261109, '2026-11-09', 2026, 11, 'Noviembre', 4, 'Lunes');

-- Poblado Fact_Atenciones
INSERT INTO Fact_Atenciones (ID_Paciente, ID_Medico, ID_Sede, ID_Diagnostico, ID_Tiempo, Costo_Atencion, Tiempo_Espera_Min, Cantidad_Medicamentos, Estado_Atencion) VALUES
(1, 1, 1, 1, 20261108, 45000.00, 25, 2, 'Completada'),
(2, 3, 2, 3, 20261109, 85000.00, 40, 3, 'Completada'),
(3, 2, 1, 1, 20261109, 50000.00, 15, 1, 'Completada');
