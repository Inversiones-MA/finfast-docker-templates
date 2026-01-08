# USO DE DOCKERFILES CENTRALIZADOS

## Deteccion Automatica

El script detect-project-type.sh analiza el repositorio y determina el Dockerfile apropiado.

Uso:
```bash
./validators/detect-project-type.sh /path/to/repo
```

Retorna el path del template a usar, ejemplo: nodejs/Dockerfile.nestjs

## Templates Disponibles

- nodejs/Dockerfile.nestjs: Para aplicaciones NestJS
- nodejs/Dockerfile.express: Para aplicaciones Express
- dotnet/Dockerfile.webapi: Para ASP.NET Core WebAPI

## Caracteristicas de los Templates

- Multi-stage build para minimizar tamaño
- Usuario no-root para seguridad
- Healthcheck configurado
- Variables de entorno predefinidas
- Optimizacion de cache de dependencias

## Agregar Nuevo Template

1. Crear archivo en templates/[lenguaje]/Dockerfile.[tipo]
2. Seguir estructura de multi-stage build
3. Incluir healthcheck
4. Ejecutar como usuario no-root
5. Actualizar script de deteccion
6. Documentar en este archivo
