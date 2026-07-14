---
# Playbook para instalar MongoDB Community Edition 7.0 de forma desatendida
# Basado en: https://www.mongodb.com/es/docs/v7.0/tutorial/install-mongodb-on-ubuntu/
#
# IMPORTANTE: MongoDB 7.0 solo publica paquetes oficiales para los codenames
# "jammy" (22.04) y "focal" (20.04). No existe repositorio para "noble" (24.04),
# que es la base de Linux Mint 22.x. Por eso aquí NO se detecta el codename
# dinámicamente (a diferencia de Docker/VirtualBox): se fija "jammy", que es
# el que la propia comunidad de MongoDB recomienda usar como compatible en
# Ubuntu 24.04 y derivadas hasta que MongoDB publique soporte oficial para
# "noble". Revisa la troubleshooting guide de MongoDB si tienes dudas:
# https://www.mongodb.com/es/docs/v7.0/reference/installation-ubuntu-community-troubleshooting/
#
# Uso:
#   ansible-playbook install_mongodb.yml -i inventario

- name: Instalar MongoDB Community Edition 7.0
  hosts: all:!localhost
  become: true
  vars:
    mongodb_keyring_path: /usr/share/keyrings/mongodb-server-7.0.gpg
    mongodb_sources_path: /etc/apt/sources.list.d/mongodb-org-7.0.list
    mongodb_apt_suite: jammy  # ver nota arriba: no existe suite "noble"

  tasks:
    - name: Actualizar caché de apt
      apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Instalar dependencias (gnupg, curl)
      apt:
        name:
          - gnupg
          - curl
        state: present

    - name: Comprobar si la clave GPG de MongoDB ya está instalada
      stat:
        path: "{{ mongodb_keyring_path }}"
      register: mongodb_keyring_stat

    - name: Descargar y convertir la clave GPG de MongoDB a formato binario
      # Se usa curl en vez del módulo get_url por el bug conocido de ansible-core
      # en Python 3.12+ (HTTPSConnection.__init__() got an unexpected keyword
      # argument 'cert_file'), visto ya en Docker/Sublime Text/KeepassXC/VirtualBox.
      # Requiere shell (no command) por el pipe entre curl y gpg.
      shell: "curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o {{ mongodb_keyring_path }} --dearmor"
      args:
        executable: /bin/bash
      when: not mongodb_keyring_stat.stat.exists

    - name: Asegurar permisos de lectura para todos en la clave GPG
      file:
        path: "{{ mongodb_keyring_path }}"
        mode: "0644"

    - name: Añadir el repositorio de MongoDB
      copy:
        dest: "{{ mongodb_sources_path }}"
        mode: "0644"
        content: "deb [ arch=amd64,arm64 signed-by={{ mongodb_keyring_path }} ] https://repo.mongodb.org/apt/ubuntu {{ mongodb_apt_suite }}/mongodb-org/7.0 multiverse\n"
      register: mongodb_repo

    - name: Actualizar caché de apt tras añadir el repositorio
      apt:
        update_cache: true
      when: mongodb_repo.changed

    - name: Instalar MongoDB Community Server
      apt:
        name: mongodb-org
        state: present

    - name: Asegurar que el servicio mongod esté activo y habilitado
      service:
        name: mongod
        state: started
        enabled: true

    - name: Verificar versión de MongoDB instalada
      # mongod --version es una herramienta de línea de comandos, segura de
      # ejecutar sin display (a diferencia de KeepassXC/Sublime Text).
      command: mongod --version
      register: mongodb_version_output
      changed_when: false

    - name: Mostrar versión de MongoDB
      debug:
        msg: "{{ mongodb_version_output.stdout_lines[0] }}"