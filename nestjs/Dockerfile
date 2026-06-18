# NestJS template CENTRALIZADO + FLEXIBLE. El workflow SIEMPRE lo usa (ignora Dockerfile local).
# Hooks por-servicio: EXTRA_APK (deps sistema) + secret npmrc (libreria privada platform-common, lugar #11).
ARG ACR_REGISTRY=docker.io/library
ARG NODE_BASE=finfast-node-base:stable        # imagen base centralizada (unifica Node/nonroot/dumb-init)
ARG EXTRA_APK=""                              # HOOK: deps de sistema per-servicio (ej "openssl git")
ARG PORT=3000

# Stage 1: deps (prod)
FROM ${ACR_REGISTRY}/${NODE_BASE} AS deps
USER root
WORKDIR /app
RUN if [ -n "$EXTRA_APK" ]; then apk add --no-cache $EXTRA_APK; fi
COPY package*.json ./
# secret npmrc montado solo en build (NO queda en la layer); si no hay lib privada, npm ci usa registry publico
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc,required=false \
    npm ci --only=production --ignore-scripts && npm cache clean --force

# Stage 2: builder
FROM ${ACR_REGISTRY}/${NODE_BASE} AS builder
USER root
WORKDIR /app
RUN if [ -n "$EXTRA_APK" ]; then apk add --no-cache $EXTRA_APK; fi
COPY package*.json ./
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc,required=false npm ci --ignore-scripts
COPY . .
RUN npm run build

# Stage 3: runner
FROM ${ACR_REGISTRY}/${NODE_BASE} AS runner
LABEL maintainer="devops@inversiones-ma.cl" project="FinFast" stack="NestJS"
WORKDIR /app
ARG EXTRA_APK=""
USER root
RUN if [ -n "$EXTRA_APK" ]; then apk add --no-cache $EXTRA_APK; fi
COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=deps --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --chown=nestjs:nodejs package*.json ./
ENV NODE_ENV=production PORT=${PORT}
USER 1001:1001
EXPOSE ${PORT}
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:'+(process.env.PORT||3000)+'/health',(r)=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))" || exit 1
CMD ["node","dist/main"]
