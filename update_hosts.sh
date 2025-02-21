#!/bin/bash
set -e
MAIN_HOSTS="hosts"

# Buscar archivos que comiencen con "US"
CUSTOM_FILES=( $(find . -maxdepth 1 -type f -name "US*") )
if [ ${#CUSTOM_FILES[@]} -eq 0 ]; then
    echo "No se encontraron archivos US*, saliendo..."
    exit 0
fi

# Función de deduplicación:
# Se permite duplicados en líneas vacías o de “comentario en blanco” (solo '#' y espacios).
# Para el resto, se genera una versión canónica quitando el '#' inicial (si existe) y recortando espacios.
dedup_file() {
    local infile="$1"
    local tmpfile
    tmpfile=$(mktemp)
    awk '{
      # Si la línea es vacía, se imprime siempre.
      if ($0 ~ /^[[:space:]]*$/) { print; next; }
      # Si la línea es un “comentario en blanco” (solo "#" y espacios), se imprime siempre.
      if ($0 ~ /^[[:space:]]*#[[:space:]]*$/) { print; next; }
      # Generar la forma canónica:
      line = $0;
      if (line ~ /^[[:space:]]*#/) {
          sub(/^[[:space:]]*#/, "", line);
      }
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line);
      if (!(line in seen)) {
          seen[line]=1;
          print
      }
    }' "$infile" > "$tmpfile"
    mv "$tmpfile" "$infile"
}

# Función para actualizar el archivo personalizado a partir del archivo principal.
update_custom() {
    local custom_file="$1"
    local tmp_file
    tmp_file=$(mktemp)

    # Leer líneas en arrays
    mapfile -t main_lines < "$MAIN_HOSTS"
    mapfile -t custom_lines < "$custom_file"

    # Si el archivo personalizado tiene una cabecera de personalización, se conserva.
    local header=""
    if [[ ${custom_lines[0]} =~ ^[[:space:]]*#\ Personalización\ específica\ para\ .* ]]; then
        header="${custom_lines[0]}"
        custom_lines=("${custom_lines[@]:1}")
    fi

    # (Opcional) Se crea un array asociativo con las líneas comentadas del personalizado,
    # aunque en esta versión la deduplicación se hará de forma global.
    declare -A commented_lines
    for line in "${custom_lines[@]}"; do
        if [[ "$line" =~ ^[[:space:]]*# ]]; then
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

    # Procesar línea por línea (respetando índices, incluidas líneas en blanco)
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
            # Existe la línea en el archivo principal (incluso si está en blanco)
            if [ $i -lt $n_custom ]; then
                # La línea existe en el personalizado.
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
            # No hay línea en el principal pero sí en el personalizado.
            if [ $i -lt $n_custom ]; then
                new_lines+=("$custom_line")
            fi
        fi
    done

    # Escribir resultado provisional y luego deduplicar.
    printf "%s\n" "${new_lines[@]}" > "$tmp_file"
    mv "$tmp_file" "$custom_file"
    dedup_file "$custom_file"
}

# Procesar cada archivo US*
for CUSTOM_FILE in "${CUSTOM_FILES[@]}"; do
    if [ ! -f "$CUSTOM_FILE" ]; then
        cp "$MAIN_HOSTS" "$CUSTOM_FILE"
        sed -i "1s/^/# Personalización específica para $CUSTOM_FILE\n/" "$CUSTOM_FILE"
        dedup_file "$CUSTOM_FILE"
    else
        update_custom "$CUSTOM_FILE"
    fi
done
