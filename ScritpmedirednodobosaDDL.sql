-- 1. CREAR LA BASE DE DATOS DEL NODO B (Simulando Sede Bosa en otro servidor)
CREATE DATABASE IF NOT EXISTS medired_nodo_bosa;

USE medired_nodo_bosa;

-- Tabla física que habita únicamente en el NODO B
CREATE TABLE IF NOT EXISTS Pacientes_Bosa (
    ID_Paciente INT PRIMARY KEY AUTO_INCREMENT,
    Documento VARCHAR(20) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Sede VARCHAR(50) DEFAULT 'Sede Bosa'
);

-- Insertamos un paciente directo en el NODO B
INSERT INTO Pacientes_Bosa (Documento, Nombre) VALUES 
('10928301', 'Laura Restrepo');


-- 2. EN EL NODO A (Data Warehouse), CREAMOS LA TABLA FEDERADA
USE medired_dw;

-- Tabla federada: NO guarda datos físicamente en Nodo A, los lee en tiempo real de Nodo B
CREATE TABLE IF NOT EXISTS Fed_Pacientes_Bosa (
    ID_Paciente INT NOT NULL,
    Documento VARCHAR(20) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Sede VARCHAR(50)
) ENGINE=FEDERATED
CONNECTION='mysql://root:@localhost:3306/medired_nodo_bosa/Pacientes_Bosa';
