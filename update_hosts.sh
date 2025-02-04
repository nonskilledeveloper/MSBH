#!/bin/bash
MAIN_HOSTS="hosts"

# Buscar archivos que comiencen con "US"
CUSTOM_FILES=($(find . -maxdepth 1 -type f -name "US*"))

# Si no hay archivos personalizados, salir sin error
if [ ${#CUSTOM_FILES[@]} -eq 0 ]; then
    echo "No se encontraron archivos US*, saliendo..."
    exit 0
fi

# Recorrer cada archivo personalizado y actualizarlo
for CUSTOM_FILE in "${CUSTOM_FILES[@]}"; do
    if [ ! -f "$CUSTOM_FILE" ]; then
        cp "$MAIN_HOSTS" "$CUSTOM_FILE"
        echo "# Personalización específica para $CUSTOM_FILE" >> "$CUSTOM_FILE"
    fi
    grep -vxFf "$CUSTOM_FILE" "$MAIN_HOSTS" >> "$CUSTOM_FILE"
done

