#!/bin/bash
PLAYBOOK="cambiar_pass.yml"
RETRY_FILE="cambiar_pass.retry"
INTERVALO=600   # segundos entre intentos (10 minutos)

# Si se pasa un argumento (grupo/subgrupo), se usa como límite
LIMIT_ARG=$1

echo "=== Despliegue inicial ==="
if [ -n "$LIMIT_ARG" ]; then
    echo "Ejecutando sólo sobre el grupo/subgrupo: $LIMIT_ARG"
    ansible-playbook "$PLAYBOOK" -l "$LIMIT_ARG"
else
    echo "Ejecutando sobre todos los hosts del inventario"
    ansible-playbook "$PLAYBOOK"
fi

# Mientras exista el retry file y tenga contenido, seguimos intentando
while [[ -s "$RETRY_FILE" ]]; do
    echo "=== Todavía quedan equipos pendientes ==="
    echo "Intentando de nuevo en $(date)..."
    ansible-playbook "$PLAYBOOK" --limit @"$RETRY_FILE"

    echo "Esperando $INTERVALO segundos antes del próximo intento..."
    sleep $INTERVALO
done

echo "=== Todos los equipos han sido actualizados con éxito ==="
