import streamlit as st
import pandas as pd
from sqlalchemy import create_engine

st.set_page_config(page_title="MediRed D.C. - Arquitectura de Datos", layout="wide")
engine_dw = create_engine('mysql+pymysql://root:@localhost:3306/medired_dw')

st.title("🏥 MediRed D.C. — Tablero Ejecutivo de Arquitectura de Datos")
st.markdown("Sistema distribuido con Data Warehouse en estrella, federación de nodos, gobernanza Ley 1581 y analítica KDD.")

# --- FILTRO LATERAL POR SEDE ---
sedes_df = pd.read_sql("SELECT DISTINCT Nombre_Sede FROM Dim_Sede", con=engine_dw)
sede_sel = st.sidebar.selectbox("Filtrar por Sede:", ["Todas"] + list(sedes_df['Nombre_Sede']))

filtro_sql = "" if sede_sel == "Todas" else f"WHERE s.Nombre_Sede = '{sede_sel}'"

# --- CARGA DE DATOS CONSOLIDADOS ---
query_main = f"""
SELECT 
    f.ID_Atencion,
    p.Nombre_Paciente,
    p.Edad,
    p.Rango_Edad,
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
{filtro_sql}
"""
df = pd.read_sql(query_main, con=engine_dw)

# --- TARJETAS DE KPI PRINCIPALES ---
col1, col2, col3, col4 = st.columns(4)
costo_prom = df['Costo_Atencion'].mean() if not df.empty else 0
tasa_efec = (len(df[df['Estado_Atencion'] == 'Completada']) / len(df) * 100) if not df.empty else 0
total_meds = int(df['Cantidad_Medicamentos'].sum()) if not df.empty else 0
espera_prom = df['Tiempo_Espera_Min'].mean() if not df.empty else 0

col1.metric("KPI 1: Costo Promedio", f"${costo_prom:,.0f} COP")
col2.metric("KPI 2: Efectividad Citas", f"{tasa_efec:.1f}%")
col3.metric("KPI 3: Medicamentos Disp.", f"{total_meds} uds")
col4.metric("KPI 4: Espera Promedio", f"{espera_prom:.1f} min")

st.divider()

# --- GRÁFICOS Y MATRIZ PIVOTE ---
c_izq, c_der = st.columns(2)

with c_izq:
    st.subheader("Ingresos por Especialidad Médica (COP)")
    ingresos_esp = df.groupby('Especialidad')['Costo_Atencion'].sum()
    st.bar_chart(ingresos_esp)

with c_der:
    st.subheader("Tiempo Medio de Espera por Rango de Edad (Min)")
    espera_edad = df.groupby('Rango_Edad')['Tiempo_Espera_Min'].mean()
    st.bar_chart(espera_edad)

st.subheader("📊 Matriz Dinámica de KPI (Sede vs. Estado de Atención)")
matriz = pd.pivot_table(
    df,
    values=['Costo_Atencion', 'Tiempo_Espera_Min', 'Cantidad_Medicamentos'],
    index=['Sede', 'Rango_Edad'],
    columns=['Estado_Atencion'],
    aggfunc={'Costo_Atencion': 'mean', 'Tiempo_Espera_Min': 'mean', 'Cantidad_Medicamentos': 'sum'},
    fill_value=0
).round(1)
st.dataframe(matriz, use_container_width=True)

# --- SECCIÓN DE GOBERNANZA Y SEGMENTACIÓN ---
tab1, tab2 = st.tabs(["🔒 Auditoría de Calidad (Gobernanza)", "🤖 Segmentación K-Means"])

with tab1:
    df_aud = pd.read_sql("SELECT * FROM Auditoria_Calidad", con=engine_dw)
    st.dataframe(df_aud, use_container_width=True)

with tab2:
    df_seg = pd.read_sql("""
        SELECT s.ID_Paciente, v.Nombre_Enmascarado, v.Edad, s.Perfil_Paciente
        FROM Dim_Segmento_Paciente s
        INNER JOIN Vw_Pacientes_Anonimizados v ON s.ID_Paciente = v.ID_Paciente
    """, con=engine_dw)
    st.dataframe(df_seg, use_container_width=True)
