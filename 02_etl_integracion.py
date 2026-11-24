import pandas as pd
import requests
from sqlalchemy import create_engine

# ==========================================
# 1. CONEXIÓN A LA BASE DE DATOS (STAGING)
# ==========================================

engine_staging = create_engine('mysql+pymysql://root:@localhost:3306/medired_staging')

engine_origen = create_engine('mysql+pymysql://root:@localhost:3306/medired_dw')

print("=== INICIANDO PIPELINE ETL ===")

# ==========================================
# 2. EXTRACCIÓN (EXTRACT)
# ==========================================

# Fuente 1: Base de Datos Relacional MySQL
print("[1/3] Extrayendo datos relacionales de pacientes...")
query_pacientes = "SELECT Documento_Hash AS documento, Nombre_Paciente AS nombre, Edad AS edad, Genero AS genero, Ciudad_Residencia AS ciudad FROM Dim_Paciente"
df_pacientes = pd.read_sql(query_pacientes, con=engine_origen)

# Fuente 2: Archivo CSV Farmacia
print("[2/3] Extrayendo datos de inventario desde CSV...")
df_farmacia = pd.read_csv('farmacia.csv', encoding='utf-8')

# FUENTE 3: API REST Pública Real (Catálogo oficial CIE-10 / ICD-10-CM del NIH)
print("[3/3] Extrayendo diagnósticos reales desde API REST pública (NIH)...")
try:
    url_api = "https://clinicaltables.nlm.nih.gov/api/icd10cm/v3/search"
    parametros = {
        "sf": "code,name",
        "terms": "acute", 
        "maxList": 15  
    }
    
    response = requests.get(url_api, params=parametros, timeout=10)
    response.raise_for_status()
    api_data = response.json()
    
    # La API devuelve una lista donde la posición [3] contiene los pares [codigo, descripcion]
    registros_cie10 = api_data[3]
    
    lista_diagnosticos = []
    for item in registros_cie10:
        codigo = item[0]
        descripcion = item[1]
        # Regla de transformación: clasificamos gravedad según el código o palabra clave
        gravedad = "Critico" if "severe" in descripcion.lower() else ("Moderado" if "acute" in descripcion.lower() else "Leve")
        
        lista_diagnosticos.append({
            "codigo_cie10": codigo,
            "descripcion": descripcion,
            "nivel_gravedad": gravedad
        })
        
    df_api = pd.DataFrame(lista_diagnosticos)

except Exception as e:
    print(f"❌ Error extrayendo de la API REST: {e}")
    df_api = pd.DataFrame()

# ==========================================
# 3. TRANSFORMACIÓN (TRANSFORM)
# ==========================================

print("Transformando y limpiando datos...")

# Limpieza Fuente 1 (Pacientes)
df_pacientes['nombre'] = df_pacientes['nombre'].str.strip().str.title()
df_pacientes['genero'] = df_pacientes['genero'].str.upper()

# Limpieza Fuente 2 (Farmacia)
df_farmacia['costo_unitario'] = df_farmacia['costo_unitario'].astype(float)

# ==========================================
# 4. CARGA (LOAD A STAGING)
# ==========================================

print("Cargando datos limpios en la capa STAGING...")

df_pacientes.to_sql('stg_pacientes', con=engine_staging, if_exists='replace', index=False)
df_farmacia.to_sql('stg_farmacia', con=engine_staging, if_exists='replace', index=False)
df_api.to_sql('stg_api_diagnosticos', con=engine_staging, if_exists='replace', index=False)

print("✅ ¡Pipeline ETL ejecutado exitosamente! Datos cargados en 'medired_staging'.")
