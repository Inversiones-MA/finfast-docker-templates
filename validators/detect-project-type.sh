#!/bin/bash
set -e

REPO_PATH=${1:-.}

cd "$REPO_PATH"

if [ -f "package.json" ]; then
    PACKAGE_CONTENT=$(cat package.json)
    
    if echo "$PACKAGE_CONTENT" | grep -q "@nestjs/core"; then
        echo "nodejs/Dockerfile.nestjs"
        exit 0
    fi
    
    if echo "$PACKAGE_CONTENT" | grep -q "\"express\""; then
        echo "nodejs/Dockerfile.express"
        exit 0
    fi
    
    echo "nodejs/Dockerfile.express"
    exit 0
fi

if ls *.csproj 1> /dev/null 2>&1; then
    CSPROJ_FILE=$(ls *.csproj | head -n 1)
    CSPROJ_CONTENT=$(cat "$CSPROJ_FILE")
    
    if echo "$CSPROJ_CONTENT" | grep -q "Microsoft.AspNetCore"; then
        echo "dotnet/Dockerfile.webapi"
        exit 0
    fi
    
    echo "dotnet/Dockerfile.webapi"
    exit 0
fi

if [ -f "requirements.txt" ]; then
    echo "python/Dockerfile.fastapi"
    exit 0
fi

if [ -f "go.mod" ]; then
    echo "go/Dockerfile.generic"
    exit 0
fi

echo "ERROR: No se pudo detectar tipo de proyecto" >&2
exit 1
