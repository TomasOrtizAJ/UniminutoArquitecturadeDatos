import pandas as pd
import requests
from sqlalchemy import create_engine

# ==========================================
# 1. CONEXIÓN A LA BASE DE DATOS (STAGING)
# ==========================================
# Cambia 'root' y '' por las credenciales de tu XAMPP/MariaDB
engine_staging = create_engine('mysql+pymysql://root:@localhost:3306/medired_staging')

print("=== INICIANDO PIPELINE ETL ===")

# ==========================================
# 2. EXTRACCIÓN (EXTRACT)
# ==========================================

# Fuente 1: Base de Datos Relacional (MySQL / Dict / Datos simulados en código)
print("[1/3] Extrayendo datos relacionales de pacientes...")
data_pacientes = [
    {"documento": "1018239102", "nombre": "  juan pérez  ", "edad": 28, "genero": "m", "ciudad": "Soacha"},
    {"documento": "52819201", "nombre": "MARÍA RODRÍGUEZ", "edad": 65, "genero": "F", "ciudad": "Bosa"},
    {"documento": "1002931023", "nombre": "carlos Gómez ", "edad": 12, "genero": "M", "ciudad": "Soacha"}
]
df_pacientes = pd.DataFrame(data_pacientes)

# Fuente 2: Archivo CSV (Insumos / Farmacia)
print("[2/3] Extrayendo datos de inventario desde CSV...")
# Para la demo se genera un DataFrame idéntico al que leerías con pd.read_csv('farmacia.csv')
data_farmacia = {
    'id_medicamento': ['MED-01', 'MED-02', 'MED-03'],
    'nombre_medicamento': ['Acetaminofén 500mg', 'Losartán 50mg', 'Amoxicilina 500mg'],
    'cantidad_dispensada': [2, 3, 1],
    'costo_unitario': [1500.0, 4500.0, 12000.0],
    'fecha_dispensacion': ['2026-11-08', '2026-11-09', '2026-11-09']
}
df_farmacia = pd.DataFrame(data_farmacia)

# Fuente 3: API REST (Simulada / JSON público)
print("[3/3] Extrayendo catálogos desde API REST pública...")
try:
    # Ejemplo con API JSON placeholder / sustituible por endpoint propio
    response = requests.get('https://jsonplaceholder.typicode.com/todos?_limit=3', timeout=5)
    api_data = response.json()
    # Mapeo transformador de la API a nuestro dominio
    df_api = pd.DataFrame([
        {"codigo_cie10": "J00", "descripcion": "Rinitis aguda / Resfriado común", "nivel_gravedad": "Leve"},
        {"codigo_cie10": "E11", "descripcion": "Diabetes mellitus tipo 2", "nivel_gravedad": "Moderado"},
        {"codigo_cie10": "I10", "descripcion": "Hipertensión esencial", "nivel_gravedad": "Moderado"}
    ])
except Exception as e:
    print(f"Error extrayendo de API: {e}")

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
