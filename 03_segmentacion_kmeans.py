import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans

# 1. Conexión a ambos nodos para extraer los datos reconstruidos
engine_dw = create_engine('mysql+pymysql://root:@localhost:3306/medired_dw')

print("=== INICIANDO SEGMENTACIÓN DE PACIENTES CON K-MEANS ===")

# Extraemos métricas consolidadas por paciente uniendo los fragmentos verticales y hechos
query = """
SELECT 
    pub.ID_Paciente,
    pub.Nombre_Paciente,
    sen.Edad,
    f.Costo_Atencion,
    f.Tiempo_Espera_Min,
    f.Cantidad_Medicamentos
FROM medired_dw.Frag_V_Paciente_Publico pub
INNER JOIN medired_nodo_bosa.Frag_V_Paciente_Sensible sen ON pub.ID_Paciente = sen.ID_Paciente
INNER JOIN medired_dw.Fact_Atenciones f ON pub.ID_Paciente = f.ID_Paciente
"""

df = pd.read_sql(query, con=engine_dw)

# 2. Selección y estandarización de variables numéricas para K-Means
features = ['Edad', 'Costo_Atencion', 'Cantidad_Medicamentos']
X = df[features]

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 3. Aplicación del modelo K-Means (3 clústeres / perfiles de atención)
kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
df['Cluster'] = kmeans.fit_predict(X_scaled)

# 4. Etiquetado e interpretación de resultados según el promedio de gasto y edad
resumen_clusters = df.groupby('Cluster')[features].mean().sort_values(by='Costo_Atencion')
orden_perfiles = {
    resumen_clusters.index[0]: 'Segmento 1: Atención Básica / Preventiva',
    resumen_clusters.index[1]: 'Segmento 2: Atención Moderada / Ambulatoria',
    resumen_clusters.index[2]: 'Segmento 3: Alta Complejidad / Crónicos'
}
df['Perfil_Paciente'] = df['Cluster'].map(orden_perfiles)

print("\n--- RESUMEN ESTADÍSTICO POR CLÚSTER (CENTROIDES REALES) ---")
print(resumen_clusters.round(2))

print("\n--- PACIENTES SEGMENTADOS ---")
print(df[['ID_Paciente', 'Nombre_Paciente', 'Edad', 'Costo_Atencion', 'Cantidad_Medicamentos', 'Perfil_Paciente']])

# 5. Guardamos los resultados segmentados en el Data Warehouse para usarlos en KPI
df[['ID_Paciente', 'Cluster', 'Perfil_Paciente']].to_sql(
    'Dim_Segmento_Paciente', con=engine_dw, if_exists='replace', index=False
)
print("\n✔ Tabla 'Dim_Segmento_Paciente' guardada en medired_dw.")

# 6. Generación de gráfico de dispersión como evidencia visual
plt.figure(figsize=(9, 5))
for cluster_id, nombre_perfil in orden_perfiles.items():
    subset = df[df['Cluster'] == cluster_id]
    plt.scatter(subset['Edad'], subset['Costo_Atencion'], label=nombre_perfil, s=100, alpha=0.8)

plt.title('Segmentación de Pacientes MediRed D.C. (K-Means)')
plt.xlabel('Edad del Paciente (Años)')
plt.ylabel('Costo de Atención (COP)')
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)
plt.tight_layout()
plt.savefig('segmentacion_kmeans_pacientes.png', dpi=150)
print("✔ Gráfico guardado como 'segmentacion_kmeans_pacientes.png'.")
