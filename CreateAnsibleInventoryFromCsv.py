#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import csv
import re
import sys

def sanitize(name):
    """
    Normaliza nombres para inventario de Ansible:
    - pasa a minúsculas
    - reemplaza cualquier carácter no alfanumérico por '_'
    - elimina '_' sobrantes al principio o final
    - si empieza por número, añade prefijo 'g_'
    """
    clean = re.sub(r'\W+', '_', name).strip('_').lower()
    if re.match(r'^\d', clean):
        clean = f"g_{clean}"
    return clean


def generar_inventario_ansible(ruta_csv, ruta_salida='hosts'):
    with open(ruta_csv, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        grupos = {}
        subgrupos = {}
        grupo_actual = None

        for fila in reader:
            if not fila or not fila[0].strip():
                continue
            entrada = fila[0].strip()
            # Línea que marca un grupo (ej: [aula1])
            if entrada.startswith('[') and entrada.endswith(']'):
                grupo_actual = entrada.strip('[]')
                grupos[grupo_actual] = []
                subgrupos[grupo_actual] = {}
            elif grupo_actual:
                partes = entrada.split(';')
                if len(partes) >= 3:
                    nombre_host = partes[0].strip()
                    ip_principal = partes[2].strip()
                    if nombre_host and ip_principal:
                        # Nombre de inventario único (host_sanitizado + sufijo de grupo)
                        sufijo = sanitize(grupo_actual)
                        inventory_name = f"{sanitize(nombre_host)}_{sufijo}"

                        # Guardamos también el nombre original como variable pc_name
                        host_line = f"{inventory_name} ansible_host={ip_principal} pc_name={nombre_host}"

                        # Añadir al grupo principal
                        grupos[grupo_actual].append(host_line)

                        # Detectar fila (ej: PC42 -> fila 4)
                        match = re.match(r"PC(\d)(\d+)", nombre_host, re.IGNORECASE)
                        if match:
                            fila_num = match.group(1)
                            subgrupo_nombre = f"{grupo_actual}_fila{fila_num}"
                            if subgrupo_nombre not in subgrupos[grupo_actual]:
                                subgrupos[grupo_actual][subgrupo_nombre] = []
                            subgrupos[grupo_actual][subgrupo_nombre].append(host_line)

    with open(ruta_salida, 'w', encoding='utf-8') as f_out:
        # Escribir grupos principales
        for grupo, hosts in grupos.items():
            grupo_sanit = sanitize(grupo)
            f_out.write(f"[{grupo_sanit}]\n")
            for host in hosts:
                f_out.write(f"{host}\n")
            f_out.write("\n")

            # Escribir subgrupos por fila
            for subgrupo, hosts_sub in subgrupos[grupo].items():
                subgrupo_sanit = sanitize(subgrupo)
                f_out.write(f"[{subgrupo_sanit}]\n")
                for host in hosts_sub:
                    f_out.write(f"{host}\n")
                f_out.write("\n")

            # Vincular subgrupos como children
            if subgrupos[grupo]:
                f_out.write(f"[{grupo_sanit}:children]\n")
                for subgrupo in subgrupos[grupo].keys():
                    f_out.write(f"{sanitize(subgrupo)}\n")
                f_out.write("\n")

        # f_out.write("[local]\n")
        # f_out.write("localhost ansible_connection=local\n")
        # f_out.write("\n")

        # Añadir sección [all:vars] al final
        f_out.write("[all:vars]\n")
        f_out.write("ansible_python_interpreter=/usr/bin/python3\n")
        # f_out.write("\n")

if __name__ == "__main__":
    if len(sys.argv) >= 2:
        csv_path = sys.argv[1]
    else:
        csv_path = 'FAI-Inventario-2025.csv'
    salida = 'hosts'
    if len(sys.argv) >= 3:
        salida = sys.argv[2]
    print(f"Generando inventario '{salida}' a partir de '{csv_path}'...")
    generar_inventario_ansible(csv_path, salida)
    print("Hecho.")
