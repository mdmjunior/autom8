FROM node:22-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build


FROM nginx:1.27-alpine AS runtime

ARG AUTOM8_VERSION=development
ARG AUTOM8_REVISION=unknown
ARG AUTOM8_BUILD_DATE=unknown

LABEL org.opencontainers.image.title="AutoM8 Website" \
      org.opencontainers.image.description="Website oficial da suíte AutoM8" \
      org.opencontainers.image.vendor="OSLabs" \
      org.opencontainers.image.version="${AUTOM8_VERSION}" \
      org.opencontainers.image.revision="${AUTOM8_REVISION}" \
      org.opencontainers.image.created="${AUTOM8_BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/mdmjunior/autom8"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

RUN test -f /usr/share/nginx/html/install.sh \
    && chmod 0644 /usr/share/nginx/html/install.sh

HEALTHCHECK \
  --interval=30s \
  --timeout=3s \
  --start-period=10s \
  --retries=3 \
  CMD wget -q -O - http://127.0.0.1/healthz | grep -qx ok || exit 1

EXPOSE 80
