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
    echo "Actualizando $CUSTOM_FILE..."

    # Crear el archivo si no existe
    if [ ! -f "$CUSTOM_FILE" ]; then
        cp "$MAIN_HOSTS" "$CUSTOM_FILE"
        echo "# Personalización específica para $CUSTOM_FILE" >> "$CUSTOM_FILE"
        continue
    fi

    # Crear archivo temporal para manejar modificaciones
    TEMP_FILE=$(mktemp)

    # Analizar el archivo principal, ignorando líneas comentadas
    while IFS= read -r line; do
        # Ignorar líneas comentadas en el archivo principal
        [[ "$line" =~ ^#.*$ ]] && continue

        HOST_KEY=$(echo "$line" | awk {print })

        # Verificar si la línea existe comentada en el archivo personalizado
        if grep -q "^#.*\\s$HOST_KEY$" "$CUSTOM_FILE"; then
            echo "Línea comentada con $HOST_KEY encontrada en $CUSTOM_FILE. Ignorando actualización y no añadiendo duplicado."
            continue
        fi

        # Si la línea existe sin comentar, eliminarla antes de añadir la nueva versión
        if grep -q "^[^#].*\\s$HOST_KEY$" "$CUSTOM_FILE"; then
            sed -i "/^[^#].*\\s$HOST_KEY$/d" "$CUSTOM_FILE"
        fi

        # Añadir la línea si no está comentada
        if ! grep -q "\\s$HOST_KEY$" "$CUSTOM_FILE"; then
            echo "$line" >> "$TEMP_FILE"
        fi
    done < "$MAIN_HOSTS"

    # Añadir líneas personalizadas antiguas que no estén en el nuevo archivo temporal
    grep -vxFf "$TEMP_FILE" "$CUSTOM_FILE" >> "$TEMP_FILE"

    mv "$TEMP_FILE" "$CUSTOM_FILE"
    echo "Actualización completada para $CUSTOM_FILE."
done

