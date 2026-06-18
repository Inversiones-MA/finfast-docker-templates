# finfast-node-base -> ACR base/finfast-node-base:vX.Y.Z (build CI staging -> import prod por digest)
# Unifica Node + nonroot(1001) + dumb-init + tini. Bump MAJOR al subir Node. UN solo lugar controla el runtime.
ARG ACR_REGISTRY=docker.io/library
ARG NODE_VERSION=20.19-alpine
FROM ${ACR_REGISTRY}/node:${NODE_VERSION}
LABEL maintainer="devops@inversiones-ma.cl" project="FinFast" component="node-base"
RUN apk add --no-cache dumb-init tini \
 && addgroup --system --gid 1001 nodejs \
 && adduser --system --uid 1001 nestjs
# NOTA: NODE_ENV se setea en el stage RUNNER del servicio, NO en la base (si no, npm ci del builder omite devDeps -> build falla exit 127)
ENTRYPOINT ["dumb-init","--"]
