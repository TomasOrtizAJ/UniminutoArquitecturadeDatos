-- =====================================================================
-- 4. CREACIÓN DE ROLES, USUARIOS Y MÍNIMO PRIVILEGIO (Ítems 34, 35, 36)
-- =====================================================================

-- Limpieza previa por si re-ejecutas el script
DROP ROLE IF EXISTS 'rol_analista_bi';
DROP ROLE IF EXISTS 'rol_auditor_calidad';
DROP USER IF EXISTS 'analista_medired'@'localhost';
DROP USER IF EXISTS 'auditor_medired'@'localhost';

-- 1. Crear Roles
CREATE ROLE 'rol_analista_bi';
CREATE ROLE 'rol_auditor_calidad';

-- 2. Asignar permisos mínimos al rol Analista BI (Solo lectura a hechos y vista anonimizada)
GRANT SELECT ON medired_dw.Fact_Atenciones TO 'rol_analista_bi';
GRANT SELECT ON medired_dw.Dim_Sede TO 'rol_analista_bi';
GRANT SELECT ON medired_dw.Dim_Diagnostico TO 'rol_analista_bi';
GRANT SELECT ON medired_dw.Dim_Tiempo TO 'rol_analista_bi';
GRANT SELECT ON medired_dw.Vw_Pacientes_Anonimizados TO 'rol_analista_bi';

-- 3. Asignar permisos al rol Auditor de Calidad
GRANT SELECT, INSERT ON medired_dw.Auditoria_Calidad TO 'rol_auditor_calidad';
GRANT SELECT ON medired_dw.Vw_Pacientes_Anonimizados TO 'rol_auditor_calidad';

-- 4. Crear usuarios físicos de prueba y asignarles su rol por defecto
CREATE USER 'analista_medired'@'localhost' IDENTIFIED BY 'Analista2026*';
CREATE USER 'auditor_medired'@'localhost' IDENTIFIED BY 'Auditor2026*';

GRANT 'rol_analista_bi' TO 'analista_medired'@'localhost';
GRANT 'rol_auditor_calidad' TO 'auditor_medired'@'localhost';

SET DEFAULT ROLE 'rol_analista_bi' FOR 'analista_medired'@'localhost';
SET DEFAULT ROLE 'rol_auditor_calidad' FOR 'auditor_medired'@'localhost';

-- 5. Aplicar explícitamente REVOKE para garantizar que el analista NO toque datos sensibles ni borre
REVOKE ALL PRIVILEGES ON medired_nodo_bosa.* FROM 'analista_medired'@'localhost';

FLUSH PRIVILEGES;
