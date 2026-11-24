import pymysql

def conectar_nodo(base_datos):
    return pymysql.connect(
        host='localhost',
        user='root',
        password='',
        database=base_datos,
        autocommit=False
    )

def consultar_estado_nodos():
    conn_a = conectar_nodo('medired_dw')
    conn_b = conectar_nodo('medired_nodo_bosa')
    with conn_a.cursor() as cur_a, conn_b.cursor() as cur_b:
        cur_a.execute("SELECT COUNT(*) FROM Fact_Atenciones")
        total_atenciones = cur_a.fetchone()[0]
        cur_b.execute("SELECT Unidades_Disponibles FROM Stock_Bosa WHERE ID_Medicamento = 'MED-01'")
        stock_bosa = cur_b.fetchone()[0]
    conn_a.close()
    conn_b.close()
    print(f"   [Estado Actual] Nodo A (Atenciones DW): {total_atenciones} | Nodo B (Stock MED-01 Bosa): {stock_bosa} uds")

def ejecutar_transaccion_distribuida(simular_fallo_nodo_b=False):
    xid_a = "'tx_medired_2026', 'nodo_a'"
    xid_b = "'tx_medired_2026', 'nodo_b'"
    
    conn_a = conectar_nodo('medired_dw')
    conn_b = conectar_nodo('medired_nodo_bosa')
    cur_a = conn_a.cursor()
    cur_b = conn_b.cursor()

    try:
        print("\n1. Iniciando transacción distribuida 2PC (XA START) en ambos nodos...")
        cur_a.execute(f"XA START {xid_a}")
        cur_b.execute(f"XA START {xid_b}")

        # Operación en Nodo A: Registrar nueva atención médica
        print("2. Ejecutando INSERT en Nodo A (medired_dw.Fact_Atenciones)...")
        cur_a.execute("""
            INSERT INTO Fact_Atenciones 
            (ID_Paciente, ID_Medico, ID_Sede, ID_Diagnostico, ID_Tiempo, Costo_Atencion, Tiempo_Espera_Min, Cantidad_Medicamentos, Estado_Atencion)
            VALUES (1, 1, 2, 1, 20261109, 55000.00, 15, 2, 'Completada')
        """)

        # Operación en Nodo B: Descontar 2 unidades de medicamento en Sede Bosa
        print("3. Ejecutando UPDATE en Nodo B (medired_nodo_bosa.Stock_Bosa)...")
        if simular_fallo_nodo_b:
            raise RuntimeError("FALLO DE CONEXIÓN / CAÍDA SIMULADA EN NODO B (Sede Bosa)")
        
        cur_b.execute("UPDATE Stock_Bosa SET Unidades_Disponibles = Unidades_Disponibles - 2 WHERE ID_Medicamento = 'MED-01'")

        # FASE 1 DEL 2PC: XA END y XA PREPARE
        print("4. Fase de votación 2PC (XA END + XA PREPARE)...")
        cur_a.execute(f"XA END {xid_a}")
        cur_b.execute(f"XA END {xid_b}")
        cur_a.execute(f"XA PREPARE {xid_a}")
        cur_b.execute(f"XA PREPARE {xid_b}")

        # FASE 2 DEL 2PC: XA COMMIT GLOBAL
        print("5. Confirmación global en ambos nodos (XA COMMIT)...")
        cur_a.execute(f"XA COMMIT {xid_a}")
        cur_b.execute(f"XA COMMIT {xid_b}")
        print("✅ TRANSACCIÓN DISTRIBUIDA CONFIRMADA CON ÉXITO EN AMBOS NODOS.")

    except Exception as e:
        print(f"\n⚠️ ERROR DETECTADO: {e}")
        print("🔄 Ejecutando reverso distribuido (XA ROLLBACK) para mantener atomicidad...")
        for cur, xid, nombre in [(cur_a, xid_a, "Nodo A"), (cur_b, xid_b, "Nodo B")]:
            try:
                cur.execute(f"XA END {xid}")
            except Exception:
                pass
            try:
                cur.execute(f"XA ROLLBACK {xid}")
                print(f"   ✔ Reverso (ROLLBACK) aplicado correctamente en {nombre}.")
            except Exception:
                pass
    finally:
        cur_a.close()
        cur_b.close()
        conn_a.close()
        conn_b.close()

if __name__ == "__main__":
    print("=== CLIENTE PYTHON: DEMOSTRACIÓN DE TRANSACCIÓN DISTRIBUIDA XA (2PC) ===")
    consultar_estado_nodos()

    print("\n--- ESCENARIO A: FALLO EN NODO B (DEMOSTRACIÓN DE REVERSO / ATOMICIDAD) ---")
    ejecutar_transaccion_distribuida(simular_fallo_nodo_b=True)
    consultar_estado_nodos()

    print("\n--- ESCENARIO B: EJECUCIÓN EXITOSA EN AMBOS NODOS (XA COMMIT) ---")
    ejecutar_transaccion_distribuida(simular_fallo_nodo_b=False)
    consultar_estado_nodos()
