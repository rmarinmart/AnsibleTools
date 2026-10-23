# AnsibleTools

Playbooks e inventario para configurar los equipos de las aulas de un instituto con ciclos de FP de informática, después de instalarlos.

## Estructura

- `FAI-Inventario-2025.csv`: inventario de origen (ver «Herramientas»).
- `ScriptsPostFAI/hosts`: inventario de Ansible. Grupos por aula (`info_1`, `fpb_2`, `g_2smr_a`, `dam_2`…) con subgrupos por fila (`<aula>_fila0`…) y `[<aula>:children]`. Cada equipo se llama `pcNN_<aula>` y tiene las variables `ansible_host` y `pc_name`. Al final está `[all:vars]` con `ansible_python_interpreter=/usr/bin/python3`.
- `ScriptsPostFAI/yamls/`: un playbook por programa o tarea.
- `ScriptsPostFAI/masters/`: un master por aula o curso que encadena playbooks con `import_playbook: ../yamls/<x>.yaml`. `paquetes_base.yaml` es lo común a todas.
- `ScriptsPostFAI/bashscripts/configure-epoptes.sh`: ejecuta `epoptes-client -c` para obtener el certificado del servidor de Epoptes. Ningún playbook lo usa.
- `ScriptsPostFAI/informes/`: informes que generan los playbooks en el nodo de control. Está en `.gitignore`.
- `ScriptsPostFAI/ejemplo_ejecucion.txt` y `ejemplo_cambio_pass_ansible.txt`: chuletas de comandos, recogidas en «Ejecución» y «Herramientas».

## Herramientas

### `CreateAnsibleInventoryFromCsv.py`: genera `hosts` a partir del CSV

```
python3 CreateAnsibleInventoryFromCsv.py FAI-Inventario-2025.csv ScriptsPostFAI/hosts
```

- **Argumentos:** el CSV (por defecto `FAI-Inventario-2025.csv`) y el fichero de salida (por defecto `hosts` en el **directorio actual**, no en `ScriptsPostFAI/`).
- **Sobrescribe el inventario entero.** El `hosts` también se edita a mano (p.ej. «PC25 en FPB1», «Pc45_ce en inventario»), así que regenerarlo puede deshacer esos cambios: hay que pasarlos antes al CSV o revisar el diff.
- **Formato del CSV:** una línea `[AULA]` por aula (`[INFO-1]`, `[DAM-2]`, `[2SMR-A]`…) y luego una línea por equipo, separada por `;`: `PC;MAC;IP;gateway;DNS1;DNS2;IP_PC01;dummy`. El 7.º campo es la IP del PC01 del aula. El script solo usa el nombre (campo 1) y la IP (campo 3).
- **Nombres del inventario:** el nombre del aula se pasa a minúsculas y los caracteres que no son letras ni números se cambian por `_`. Si empieza por un número, se le añade el prefijo `g_` (`2SMR-A` → `g_2smr_a`). Cada equipo queda como `<pc>_<aula>` (`PC42` en `DAM-2` → `pc42_dam_2`).
- **Filas:** la fila es la primera cifra tras `PC` (`PC42` → `dam_2_fila4`, `PC01` → `fila0`). Los equipos cuyo nombre no sigue el patrón `PC<cifra><cifras>` no entran en ninguna fila.

### `CreatePasswordHash.py`: genera el hash SHA-512 de una contraseña

```
python3 CreatePasswordHash.py          # la pide sin mostrarla (mejor)
python3 CreatePasswordHash.py 'clave'  # por argumento: queda en el historial
```

- Necesita `python3-passlib`. Usa `sha512_crypt` con 5000 rondas y produce un hash `$6$…`.
- Su uso es `yamls/cambiar_pass.yaml`, que cambia la contraseña del usuario local **`mantenimiento`**. Para cambiarla:
  1. Pegar el hash en `nueva_pass`.
  2. **Subir `pass_version`** (p.ej. `"004"` → `"005"`). El playbook solo cambia la contraseña en los equipos cuyo `/var/ansible/passVersion` no coincide con esa versión, y después la escribe ahí.
  3. Lanzarlo: `sudo ansible-playbook yamls/cambiar_pass.yaml -i ./hosts -l g_2smr_a_fila4`.

## Ejecución

- Se lanza desde un servidor de Ansible, siempre **desde la carpeta `ScriptsPostFAI` y con `sudo`**:
  `sudo ansible-playbook -i ./hosts -l pc11_dam_2 masters/ejemplo_master.yaml`
- Con `-l` se limita a un equipo (`pc11_dam_2`), a un aula (`dam_2`) o a una fila (`dam_2_fila4`). Se pueden combinar separándolos por comas.
- Para comprobar la conexión y el inventario: `sudo ansible -i ./hosts pc11_dam_2 -m ping`.
- Las rutas relativas de las tareas delegadas a `localhost` se resuelven desde la carpeta del playbook (`yamls/`), también cuando se importa desde un master. Para escribir en `ScriptsPostFAI/informes/` se usa `../informes/...`, y hay que crear la carpeta antes porque `copy` no la crea.
- Si varios equipos escriben en el mismo fichero local, se pierden líneas (`lineinfile` en paralelo). En su lugar, cada equipo guarda su resultado en un fact y el informe se construye una sola vez con `run_once` a partir de `hostvars` y `ansible_play_hosts_all`. Ver `virtualbox.yaml`.
- El equipo de desarrollo del usuario es personal (CachyOS), no un equipo de aula, y no tiene Ansible instalado. Para hacer `--syntax-check` o probar plantillas, se instala `ansible-core` en un venv temporal.

## Convenciones de los playbooks

- Nombres de tareas, comentarios y mensajes en castellano. Comentarios que expliquen el porqué.
- Variables con el prefijo del playbook (`virtualbox_*`, `vbdiag_*`…).
- Las claves GPG se descargan con `curl | gpg --dearmor` en lugar de `get_url`, por un bug de ansible-core con Python 3.12+ (`cert_file`).
- Codename del repositorio: `${UBUNTU_CODENAME:-$VERSION_CODENAME}` de `/etc/os-release`, no `ansible_distribution_release`, que en Mint devuelve el codename propio (p.ej. "zena").
- Nada interactivo: nada puede quedarse esperando una entrada por teclado (p.ej. `mokutil --import` pide una contraseña por `/dev/tty`).

## Equipos de aula

- Linux Mint en todas las aulas salvo INFO2 (`info_2`), que usa LliureX.
- El PC01 de cada aula es el equipo del profesor.
- Algunas aulas, entre ellas dam_2, tienen **dos discos**: uno de Conselleria (Windows + LliureX) y otro con Mint, que ha añadido el departamento y es el que usan los alumnos.
- La **BIOS tiene contraseña de Conselleria** y el departamento no la tiene, así que no se puede desactivar Secure Boot.
- Mint se reinstala desde una ISO nueva al acabar cada curso y después se configura con los masters. La última vez fue en julio de 2026, con Mint 22.3.
- `ciclosm` y `ciclost` son siempre usuarios locales.

## VirtualBox y Secure Boot

- El paquete de Oracle (`virtualbox-7.2`) no usa DKMS. Compila `vboxdrv` con `/usr/lib/virtualbox/vboxdrv.sh` (es lo que ejecuta `vboxconfig`, y también lo hace el servicio `vboxdrv` al arrancar si no hay módulo para el kernel en ejecución). Lo firma con `/var/lib/shim-signed/mok/MOK.{der,priv}`.
- Las actualizaciones de kernel **no** obligan a volver a enrolar la clave: el módulo se recompila y se firma solo, siempre que estén las cabeceras. `virtualbox.yaml` instala el metapaquete de cabeceras (`linux-headers-generic[-hwe-XX.XX]`) y, si la clave ya está enrolada (`mokutil --test-key`), lanza `vboxconfig` también con Secure Boot activo.
- La clave `localhost.localdomain Secure Boot Module Signature key` viene **dentro de la ISO de Mint**. Es idéntica en todos los equipos instalados con la misma ISO; la de Mint 22.3 se generó hacia el 8 de enero de 2026 y tiene número de serie `3E38008F…`. Por eso:
  - reinstalar con la misma ISO no obliga a enrolar la clave de nuevo;
  - cambiar de versión de Mint o de placa base sí obliga. Como cada curso se reinstala con una ISO nueva, el enrolado de principio de curso es normal y esperado.
- En el firmware también hay claves de LliureX (del otro disco) y la clave de Mint 21.3 (de 2024).
- Diagnóstico: `yamls/virtualbox_diagnostico.yaml` (solo lectura). Deja los informes en `informes/diagnostico_virtualbox/`. Hay que ejecutarlo **antes** de arreglar a mano un equipo que falle; si no, se pierde la causa.
- Estado en octubre de 2026 (dam_2): todos los equipos estaban bien. Excepciones:
  - PC42 tiene la validación de shim desactivada en lugar de la clave enrolada. Durante ese curso se sustituyó un equipo del aula, y por su firmware podría ser PC42, pero no está confirmado.
  - PC45 conserva kernels 5.15 (de la base Ubuntu 22.04), que una instalación limpia de Mint 22.3 no tendría. No se sabe si se reinstaló desde la ISO.
  - PC23 tiene enrolada una clave "VirtualBox", generada hacia septiembre de 2026. No se sabe quién la añadió.
  - PC23 y PC26 siguen con el kernel 6.14 y no han recibido el 6.17. No se sabe por qué.
- Sigue sin saberse qué causa que algunos equipos vuelvan a necesitar el paso manual a mitad de curso. Una hipótesis plausible es que una actualización o un reseteo de la BIOS por parte de Conselleria borre la lista MOK.
