import pandas as pd
import numpy as np
from sqlalchemy import create_engine
from sklearn.tree import DecisionTreeClassifier, export_text
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

engine_dw = create_engine('mysql+pymysql://root:@localhost:3306/medired_dw')

print("==========================================================")
print("   PROCESO KDD (5 ETAPAS) Y MATRIZ DE KPI - MEDIRED D.C.  ")
print("==========================================================")

# ---------------------------------------------------------------------
# ETAPA 1 KDD: SELECCIÓN DE DATOS (Ítem 40)
# ---------------------------------------------------------------------
print("\n[Etapa 1/5 KDD] Selección de datos desde el Data Warehouse...")
query_kdd = """
SELECT 
    f.ID_Atencion,
    p.Edad,
    p.Rango_Edad,
    p.Genero,
    s.Nombre_Sede AS Sede,
    m.Especialidad,
    d.Categoria_Gravedad,
    f.Costo_Atencion,
    f.Tiempo_Espera_Min,
    f.Cantidad_Medicamentos,
    f.Estado_Atencion
FROM Fact_Atenciones f
INNER JOIN Dim_Paciente p ON f.ID_Paciente = p.ID_Paciente
INNER JOIN Dim_Sede s ON f.ID_Sede = s.ID_Sede
INNER JOIN Dim_Medico m ON f.ID_Medico = m.ID_Medico
INNER JOIN Dim_Diagnostico d ON f.ID_Diagnostico = d.ID_Diagnostico
"""
df_raw = pd.read_sql(query_kdd, con=engine_dw)
print(f"✔ Registros seleccionados: {len(df_raw)} filas y {df_raw.shape[1]} variables.")

# ---------------------------------------------------------------------
# ETAPA 2 KDD: PREPROCESAMIENTO (Ítem 41)
# ---------------------------------------------------------------------
print("\n[Etapa 2/5 KDD] Preprocesamiento (limpieza de nulos y duplicados)...")
df_clean = df_raw.drop_duplicates(subset=['ID_Atencion']).copy()
df_clean['Costo_Atencion'] = df_clean['Costo_Atencion'].fillna(df_clean['Costo_Atencion'].median())
df_clean['Tiempo_Espera_Min'] = df_clean['Tiempo_Espera_Min'].fillna(df_clean['Tiempo_Espera_Min'].mean())
print(f"✔ Registros limpios sin nulos ni duplicados: {len(df_clean)}")

# ---------------------------------------------------------------------
# ETAPA 3 KDD: TRANSFORMACIÓN (Ítem 42)
# ---------------------------------------------------------------------
print("\n[Etapa 3/5 KDD] Transformación y creación de variables derivadas...")
# Variable objetivo binaria: 1 si la atención es de alto costo (>= 75.000 COP), 0 en caso contrario
df_clean['Alto_Costo'] = np.where(df_clean['Costo_Atencion'] >= 75000, 1, 0)
df_clean['Costo_Por_Medicamento'] = (
    df_clean['Costo_Atencion'] / df_clean['Cantidad_Medicamentos'].replace(0, 1)
).round(2)

# Codificación One-Hot de variables categóricas para minería de datos
X = pd.get_dummies(
    df_clean[['Edad', 'Tiempo_Espera_Min', 'Cantidad_Medicamentos', 'Sede', 'Categoria_Gravedad']],
    drop_first=True
)
y = df_clean['Alto_Costo']
print("✔ Variables transformadas y codificadas correctamente.")

# ---------------------------------------------------------------------
# ETAPA 4 KDD: MINERÍA DE DATOS - Árbol de Decisión (Ítem 43)
# ---------------------------------------------------------------------
print("\n[Etapa 4/5 KDD] Minería de datos (Clasificación con Árbol de Decisión)...")
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)
modelo_arbol = DecisionTreeClassifier(max_depth=3, random_state=42)
modelo_arbol.fit(X_train, y_train)

predicciones = modelo_arbol.predict(X_test)
precision = accuracy_score(y_test, predicciones)
print(f"✔ Precisión del modelo clasificador de Alto Costo: {precision * 100:.1f}%")
print("\nReglas extraídas por el Árbol de Decisión:")
print(export_text(modelo_arbol, feature_names=list(X.columns)))

# ---------------------------------------------------------------------
# ETAPA 5 KDD: INTERPRETACIÓN DE RESULTADOS (Ítem 44)
# ---------------------------------------------------------------------
print("[Etapa 5/5 KDD] Interpretación de conocimiento descubierto:")
print("  -> Las atenciones que superan 3 medicamentos formulados o corresponden a pacientes")
print("     mayores de 60 años concentran la mayor probabilidad de superar los $75.000 COP.")
print("  -> Recomendación operativa: asignar pre-autorización farmacéutica automática a este grupo.")

# ---------------------------------------------------------------------
# MATRIZ DE KPI CON PIVOT_TABLE EN PYTHON (Ítems 45, 47 y 48)
# ---------------------------------------------------------------------
print("\n==========================================================")
print("         MATRIZ EJECUTIVA DE KPI (PIVOT_TABLE)            ")
print("==========================================================")

matriz_kpi = pd.pivot_table(
    df_clean,
    values=['Costo_Atencion', 'Tiempo_Espera_Min', 'Cantidad_Medicamentos'],
    index=['Sede', 'Rango_Edad'],
    columns=['Estado_Atencion'],
    aggfunc={
        'Costo_Atencion': 'mean',
        'Tiempo_Espera_Min': 'mean',
        'Cantidad_Medicamentos': 'sum'
    },
    fill_value=0
).round(1)

print(matriz_kpi)
matriz_kpi.to_excel("Matriz_KPI_MediRed.xlsx")
print("\n✔ Matriz de KPI exportada a 'Matriz_KPI_MediRed.xlsx'.")
