#!/bin/bash
PLAYBOOK="cambiar_pass.yml"
RETRY_FILE="cambiar_pass.retry"
INTERVALO=600   # segundos entre intentos (10 minutos)

echo "=== Despliegue inicial ==="
ansible-playbook "$PLAYBOOK"

# Mientras exista el retry file y tenga contenido, seguimos intentando
while [[ -s "$RETRY_FILE" ]]; do
    echo "=== Todavía quedan equipos pendientes ==="
    echo "Intentando de nuevo en $(date)..."
    ansible-playbook "$PLAYBOOK" --limit @"$RETRY_FILE"

    echo "Esperando $INTERVALO segundos antes del próximo intento..."
    sleep $INTERVALO
done

echo "=== Todos los equipos han sido actualizados con éxito ==="
