#!/bin/bash
set -e
MAIN_HOSTS="hosts"

# Buscar archivos que comiencen con "US"
CUSTOM_FILES=( $(find . -maxdepth 1 -type f -name "US*") )

if [ ${#CUSTOM_FILES[@]} -eq 0 ]; then
    echo "No se encontraron archivos US*, saliendo..."
    exit 0
fi

# Función para actualizar el archivo personalizado en base al archivo principal.
update_custom() {
    local custom_file="$1"
    local tmp_file
    tmp_file=$(mktemp)

    # Leer líneas del archivo principal y del personalizado en arrays.
    mapfile -t main_lines < "$MAIN_HOSTS"
    mapfile -t custom_lines < "$custom_file"

    # Si el archivo personalizado tiene una cabecera de personalización, se conserva.
    local header=""
    if [[ ${custom_lines[0]} =~ ^[[:space:]]*#\ Personalización\ específica\ para\ .* ]]; then
        header="${custom_lines[0]}"
        custom_lines=("${custom_lines[@]:1}")
    fi

    # Crear un array asociativo con las líneas comentadas del personalizado (sin el símbolo "#").
    declare -A commented_lines
    for line in "${custom_lines[@]}"; do
        if [[ "$line" =~ ^[[:space:]]*# ]]; then
            # Remover el símbolo '#' y recortar espacios en blanco a ambos lados.
            trimmed="${line#\#}"
            trimmed="$(echo -e "$trimmed" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
            if [ -n "$trimmed" ]; then
                commented_lines["$trimmed"]=1
            fi
        fi
    done

    local n_main=${#main_lines[@]}
    local n_custom=${#custom_lines[@]}
    local max=$n_main
    if [ $n_custom -gt $max ]; then
        max=$n_custom
    fi

    new_lines=()
    # Incluir la cabecera si existe.
    if [ -n "$header" ]; then
        new_lines+=("$header")
    fi

    for (( i=0; i<max; i++ )); do
        local main_line=""
        local custom_line=""
        if [ $i -lt $n_main ]; then
            main_line="${main_lines[i]}"
        fi
        if [ $i -lt $n_custom ]; then
            custom_line="${custom_lines[i]}"
        fi

        if [ $i -lt $n_main ]; then
            # Existe la línea en el archivo principal (incluso si está en blanco).
            if [ $i -lt $n_custom ]; then
                # La línea existe en el archivo personalizado.
                if [[ "$custom_line" =~ ^[[:space:]]*# ]]; then
                    new_lines+=("$custom_line")
                else
                    if [ "$custom_line" != "$main_line" ]; then
                        new_lines+=("$main_line")
                    else
                        new_lines+=("$custom_line")
                    fi
                fi
            else
                new_lines+=("$main_line")
            fi
        else
            # No existe la línea en el archivo principal, pero sí en el personalizado.
            if [ $i -lt $n_custom ]; then
                new_lines+=("$custom_line")
            fi
        fi
    done

    # Escribir el resultado en el archivo temporal y reemplazar el archivo personalizado.
    printf "%s\n" "${new_lines[@]}" > "$tmp_file"
    mv "$tmp_file" "$custom_file"
}

for CUSTOM_FILE in "${CUSTOM_FILES[@]}"; do
    if [ ! -f "$CUSTOM_FILE" ]; then
        cp "$MAIN_HOSTS" "$CUSTOM_FILE"
        sed -i "1s/^/# Personalización específica para $CUSTOM_FILE\n/" "$CUSTOM_FILE"
    else
        update_custom "$CUSTOM_FILE"
    fi
done
