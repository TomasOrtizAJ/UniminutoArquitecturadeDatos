from sqlalchemy import create_engine, text

# Conectamos usando el usuario restringido 'analista_medired'
engine_restringido = create_engine('mysql+pymysql://analista_medired:Analista2026*@localhost:3306/medired_dw')

with engine_restringido.connect() as conn:
    print("1. Intentando consultar vista anonimizada (PERMITIDO):")
    res = conn.execute(text("SELECT * FROM Vw_Pacientes_Anonimizados LIMIT 3")).fetchall()
    for fila in res:
        print("  ✔", fila)

    print("\n2. Intentando consultar tabla sensible Dim_Paciente directamente (BLOQUEADO):")
    try:
        conn.execute(text("SELECT Nombre_Paciente, Documento_Hash FROM Dim_Paciente")).fetchall()
    except Exception as e:
        print("  🛑 ACCESO DENEGADO EXITOSAMENTE (Cumplimiento Ley 1581):")
        print("    ", e.orig)
