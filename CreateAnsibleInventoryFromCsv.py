import csv

def generar_inventario_ansible(ruta_csv, ruta_salida='hosts'):
    with open(ruta_csv, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        grupos = {}
        grupo_actual = None

        for fila in reader:
            if not fila or not fila[0].strip():
                continue
            entrada = fila[0].strip()
            if entrada.startswith('[') and entrada.endswith(']'):
                grupo_actual = entrada.strip('[]')
                grupos[grupo_actual] = []
            elif grupo_actual:
                partes = entrada.split(';')
                if len(partes) >= 3:
                    nombre_host = partes[0].strip()
                    ip_principal = partes[2].strip()
                    if nombre_host and ip_principal:
                        grupos[grupo_actual].append(f"{nombre_host} ansible_host={ip_principal}")

    with open(ruta_salida, 'w', encoding='utf-8') as f_out:
        for grupo, hosts in grupos.items():
            f_out.write(f"[{grupo}]\n")
            for host in hosts:
                f_out.write(f"{host}\n")
            f_out.write("\n")

        # Añadir sección [all:vars] al final
        f_out.write("[all:vars]\n")
        f_out.write("ansible_python_interpreter=/usr/bin/python3\n")

# Ejemplo de uso
generar_inventario_ansible('FAI-Inventario-2025.csv')

