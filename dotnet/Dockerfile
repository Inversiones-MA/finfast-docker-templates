# =============================================================================
# Multi-stage build para .NET WebAPI
# Soporta: proyectos simples Y monorepos con subdirectorios
# =============================================================================
#
# BUILD ARGS:
#   PROJECT_PATH  - Ruta al proyecto .csproj (ej: "src/MiApi" o "MiRepo/MiApi")
#                   Si vacio, busca automaticamente en la raiz
#   ENTRY_DLL     - Nombre del DLL de entrada (ej: "MiApi.dll")
#                   Si vacio, se auto-detecta del nombre del proyecto
#   SOLUTION_FILE - Archivo .sln para restore (opcional, mejora cache)
#
# EJEMPLOS DE USO:
#   # Proyecto simple (csproj en raiz):
#   docker build -t mi-app .
#
#   # Monorepo con proyecto en subdirectorio:
#   docker build --build-arg PROJECT_PATH=MultiGarantias2/MultiGarantias2.ApiEquifax -t mi-app .
#
#   # Monorepo especificando solucion:
#   docker build --build-arg PROJECT_PATH=src/MiApi --build-arg SOLUTION_FILE=MiSolucion.sln -t mi-app .
#
# =============================================================================

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Build args con valores por defecto
ARG PROJECT_PATH=""
ARG ENTRY_DLL=""
ARG SOLUTION_FILE=""
ARG BUILD_DATE=""
ARG GIT_COMMIT=""
ARG GIT_BRANCH=""

WORKDIR /src

# Copiar todo el codigo fuente primero
COPY . .

# Script de deteccion y build inteligente
RUN <<'EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "DOTNET BUILD - Auto-deteccion de proyecto"
echo "=========================================="
echo "PROJECT_PATH arg: ${PROJECT_PATH:-'(no especificado)'}"
echo "SOLUTION_FILE arg: ${SOLUTION_FILE:-'(no especificado)'}"
echo "ENTRY_DLL arg: ${ENTRY_DLL:-'(auto-detectar)'}"
echo ""

# Funcion para encontrar csproj
find_csproj() {
    local search_path="$1"
    find "$search_path" -maxdepth 2 -name "*.csproj" -type f 2>/dev/null | head -1
}

# Funcion para encontrar sln
find_sln() {
    local search_path="$1"
    find "$search_path" -maxdepth 2 -name "*.sln" -type f 2>/dev/null | head -1
}

# Determinar PROJECT_PATH si no se especifico
if [ -z "$PROJECT_PATH" ]; then
    echo "Buscando proyecto automaticamente..."

    # Caso 1: csproj en la raiz
    if ls *.csproj 1>/dev/null 2>&1; then
        PROJECT_PATH="."
        echo "  -> Encontrado csproj en raiz"
    else
        # Caso 2: Buscar en subdirectorios (monorepo)
        # Primero buscar directorios que parezcan proyectos API/Service
        for pattern in "*Api*" "*Service*" "*Web*" "src/*"; do
            for dir in $pattern; do
                if [ -d "$dir" ] && ls "$dir"/*.csproj 1>/dev/null 2>&1; then
                    PROJECT_PATH="$dir"
                    echo "  -> Encontrado proyecto en: $dir"
                    break 2
                fi
            done
        done

        # Si aun no encontramos, buscar cualquier csproj
        if [ -z "$PROJECT_PATH" ]; then
            FOUND_CSPROJ=$(find_csproj ".")
            if [ -n "$FOUND_CSPROJ" ]; then
                PROJECT_PATH=$(dirname "$FOUND_CSPROJ")
                echo "  -> Encontrado csproj en: $PROJECT_PATH"
            fi
        fi
    fi
fi

# Validar que encontramos un proyecto
if [ -z "$PROJECT_PATH" ]; then
    echo "ERROR: No se encontro ningun proyecto .NET"
    echo "Especifique PROJECT_PATH como build-arg"
    echo ""
    echo "Estructura del repositorio:"
    find . -name "*.csproj" -o -name "*.sln" 2>/dev/null | head -20
    exit 1
fi

# Normalizar PROJECT_PATH (quitar ./ inicial y / final)
PROJECT_PATH=$(echo "$PROJECT_PATH" | sed 's|^./||' | sed 's|/$||')

echo ""
echo "Usando PROJECT_PATH: $PROJECT_PATH"

# Encontrar el archivo csproj
if [ "$PROJECT_PATH" = "." ]; then
    CSPROJ_FILE=$(ls *.csproj 2>/dev/null | head -1)
else
    CSPROJ_FILE=$(ls "$PROJECT_PATH"/*.csproj 2>/dev/null | head -1)
fi

if [ -z "$CSPROJ_FILE" ]; then
    echo "ERROR: No se encontro archivo .csproj en $PROJECT_PATH"
    echo "Archivos disponibles:"
    ls -la "$PROJECT_PATH"/ 2>/dev/null || ls -la .
    exit 1
fi

echo "Archivo csproj: $CSPROJ_FILE"

# Determinar ENTRY_DLL si no se especifico
if [ -z "$ENTRY_DLL" ]; then
    # Extraer nombre del proyecto del csproj
    PROJECT_NAME=$(basename "$CSPROJ_FILE" .csproj)
    ENTRY_DLL="${PROJECT_NAME}.dll"
fi

echo "Entry DLL: $ENTRY_DLL"

# Guardar variables para las siguientes etapas
echo "$PROJECT_PATH" > /tmp/project_path
echo "$ENTRY_DLL" > /tmp/entry_dll
echo "$CSPROJ_FILE" > /tmp/csproj_file

# Buscar solucion para mejor cache de restore
if [ -n "$SOLUTION_FILE" ] && [ -f "$SOLUTION_FILE" ]; then
    echo "Usando solucion especificada: $SOLUTION_FILE"
    echo "$SOLUTION_FILE" > /tmp/solution_file
else
    FOUND_SLN=$(find_sln ".")
    if [ -n "$FOUND_SLN" ]; then
        echo "Solucion encontrada: $FOUND_SLN"
        echo "$FOUND_SLN" > /tmp/solution_file
    fi
fi

echo ""
echo "=========================================="
echo "Ejecutando dotnet restore..."
echo "=========================================="

# Restore: usar siempre el proyecto especifico
# En monorepos, la solucion puede tener proyectos con dependencias no disponibles
# Por lo tanto, restauramos solo el proyecto que necesitamos
echo "Restaurando proyecto: $CSPROJ_FILE"
dotnet restore "$CSPROJ_FILE"

echo ""
echo "=========================================="
echo "Ejecutando dotnet build..."
echo "=========================================="

dotnet build "$CSPROJ_FILE" -c Release -o /app/build --no-restore

EOF

# Etapa de publish
FROM build AS publish
RUN CSPROJ_FILE=$(cat /tmp/csproj_file) && \
    dotnet publish "$CSPROJ_FILE" -c Release -o /app/publish --no-restore /p:UseAppHost=false

# Etapa final - imagen de runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final

LABEL maintainer="devops@inversiones-ma.cl"
LABEL project="FinFast"
LABEL stack=".NET 8"

# Crear usuario no-root
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --ingroup appgroup appuser

WORKDIR /app

# Copiar artefactos publicados
COPY --from=publish --chown=appuser:appgroup /app/publish .

# Copiar nombre del DLL de entrada
COPY --from=build /tmp/entry_dll /tmp/entry_dll

# Variables de entorno
ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://+:3000

USER appuser

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Entrypoint dinamico usando el DLL detectado
ENTRYPOINT ["/bin/sh", "-c", "dotnet $(cat /tmp/entry_dll)"]
