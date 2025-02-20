#!/bin/bash
MAIN_HOSTS="hosts"

# Buscar archivos personalizados que comiencen con "US"
CUSTOM_FILES=($(find . -maxdepth 1 -type f -name "US*"))

# Si no hay archivos personalizados, salir sin error
if [ ${#CUSTOM_FILES[@]} -eq 0 ]; then
    echo "No se encontraron archivos US*, saliendo..."
    exit 0
fi

for CUSTOM_FILE in "${CUSTOM_FILES[@]}"; do
    # Si el archivo personalizado no existe, se crea copiando el archivo principal
    if [ ! -f "$CUSTOM_FILE" ]; then
        cp "$MAIN_HOSTS" "$CUSTOM_FILE"
        echo "# Personalización específica para $CUSTOM_FILE" >> "$CUSTOM_FILE"
    else
        # Se crea un archivo temporal para generar la versión actualizada
        TMP=$(mktemp)

        # Procesar cada línea del archivo principal
        while IFS= read -r main_line || [ -n "$main_line" ]; do
            # Si la línea exacta ya existe (sin comentario) en el archivo personalizado
            if grep -Fxq "$main_line" "$CUSTOM_FILE"; then
                echo "$main_line" >> "$TMP"
            # Si la misma línea existe comentada
            elif grep -Fq "#$main_line" "$CUSTOM_FILE"; then
                grep -F "#$main_line" "$CUSTOM_FILE" >> "$TMP"
            else
                # Buscar línea similar por el segundo campo (nombre de host)
                host_key=$(echo "$main_line" | awk {print })
                if [ -n "$host_key" ]; then
                    existing=$(grep -v ^# "$CUSTOM_FILE" | grep -F " $host_key")
                    if [ -n "$existing" ]; then
                        echo "$main_line" >> "$TMP"
                        continue
                    fi
                fi
                echo "$main_line" >> "$TMP"
            fi
        done < "$MAIN_HOSTS"

        # Conservar líneas comentadas personalizadas
        while IFS= read -r custom_line || [ -n "$custom_line" ]; do
            if [[ "$custom_line" =~ ^# ]]; then
                uncommented=$(echo "$custom_line" | sed s/^#//)
                if ! grep -Fxq "$custom_line" "$TMP" && ! grep -Fxq "#$uncommented" "$TMP"; then
                    echo "$custom_line" >> "$TMP"
                fi
            fi
        done < "$CUSTOM_FILE"

        mv "$TMP" "$CUSTOM_FILE"
    fi
done

