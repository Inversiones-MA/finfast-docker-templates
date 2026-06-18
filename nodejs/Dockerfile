# nodejs template CENTRALIZADO + FLEXIBLE. Workflow SIEMPRE lo usa (ignora Dockerfile local). Hooks: EXTRA_APK + secret npmrc (lib privada).
ARG ACR_REGISTRY=docker.io/library
ARG NODE_BASE=finfast-node-base:stable
ARG EXTRA_APK=""
ARG PORT=3000
FROM ${ACR_REGISTRY}/${NODE_BASE} AS deps
USER root
WORKDIR /app
RUN if [ -n "$EXTRA_APK" ]; then apk add --no-cache $EXTRA_APK; fi
COPY package*.json ./
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc,required=false npm ci --only=production --ignore-scripts && npm cache clean --force
FROM ${ACR_REGISTRY}/${NODE_BASE} AS runner
LABEL maintainer="devops@inversiones-ma.cl" project="FinFast" stack="nodejs"
WORKDIR /app
ARG EXTRA_APK=""
USER root
RUN if [ -n "$EXTRA_APK" ]; then apk add --no-cache $EXTRA_APK; fi
COPY --from=deps --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --chown=nestjs:nodejs . .
ENV NODE_ENV=production PORT=${PORT}
USER 1001:1001
EXPOSE ${PORT}
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:'+(process.env.PORT||3000)+'/health',(r)=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))" || exit 1
CMD ["node", "index.js"]
