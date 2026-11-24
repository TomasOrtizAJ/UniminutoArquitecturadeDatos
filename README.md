# Arquitectura de Datos Distribuida y Data Warehouse — MediRed D.C.

Proyecto final del curso **Arquitectura de Datos** (Ingeniería de Sistemas — UNIMINUTO Soacha). Implementa una arquitectura por capas, integración ETL heterogénea, federación entre nodos, fragmentación horizontal/vertical, gobernanza bajo la Ley 1581 de 2012, minería de datos (KDD), transacciones distribuidas 2PC (`XA`) y tablero analítico.

## Requisitos Previos
* **XAMPP** con MariaDB / MySQL activo en el puerto `3306`.
* **Python 3.11+** con las dependencias instaladas:
  ```bash
  pip install pandas sqlalchemy pymysql requests openpyxl pdfplumber scikit-learn matplotlib streamlit
