USE medired_dw;

SELECT ID_Paciente, Nombre_Paciente AS Nombre, 'Nodo A - Soacha' AS Origen 
FROM Dim_Paciente
UNION ALL
SELECT ID_Paciente, Nombre, Sede AS Origen 
FROM Fed_Pacientes_Bosa;
