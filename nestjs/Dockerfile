# Multi-stage build para NestJS
# Optimizado para produccion
# ACR_REGISTRY: si se pasa, usa imagenes base desde ACR (evita Docker Hub rate limits)
# Si no se pasa, usa docker.io/library como fallback (compatible con builds locales)
ARG ACR_REGISTRY=docker.io/library

# Stage 1: Dependencies
FROM ${ACR_REGISTRY}/node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production --ignore-scripts && \
    npm cache clean --force

# Stage 2: Builder
FROM ${ACR_REGISTRY}/node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --ignore-scripts

COPY . .

RUN npm run build

# Stage 3: Runner
FROM ${ACR_REGISTRY}/node:20-alpine AS runner

LABEL maintainer="devops@inversiones-ma.cl"
LABEL project="FinFast"
LABEL stack="NestJS"

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nestjs

WORKDIR /app

COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=deps --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --chown=nestjs:nodejs package*.json ./

ENV NODE_ENV=production \
    PORT=3000

USER nestjs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

CMD ["node", "dist/main"]
