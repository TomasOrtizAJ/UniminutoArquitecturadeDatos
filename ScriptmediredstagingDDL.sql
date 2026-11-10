USE medired_staging;

-- Tabla staging para Pacientes (Fuente BD Relacional)
CREATE TABLE IF NOT EXISTS stg_pacientes (
    documento VARCHAR(20),
    nombre VARCHAR(100),
    edad INT,
    genero CHAR(1),
    ciudad VARCHAR(50)
);

-- Tabla staging para Farmacia (Fuente CSV)
CREATE TABLE IF NOT EXISTS stg_farmacia (
    id_medicamento VARCHAR(20),
    nombre_medicamento VARCHAR(100),
    cantidad_dispensada INT,
    costo_unitario DECIMAL(10, 2),
    fecha_dispensacion VARCHAR(20)
);

-- Tabla staging para API Externa (Fuente JSON/API REST)
CREATE TABLE IF NOT EXISTS stg_api_diagnosticos (
    codigo_cie10 VARCHAR(10),
    descripcion VARCHAR(150),
    nivel_gravedad VARCHAR(20)
);
