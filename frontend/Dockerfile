# syntax=docker/dockerfile:1
# Build web de l'app Flutter, servi par nginx. Consommé par
# ../infra/docker-compose.web.yml (preview web derrière Traefik).

FROM debian:bookworm-slim AS flutter
ARG FLUTTER_VERSION=3.47.7
RUN apt-get update \
    && apt-get install -y --no-install-recommends git curl unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics --enable-web && flutter precache --web

FROM flutter AS build
ARG BASE_HREF=/keepmydiet/
ARG API_BASE_URL=/keepmydiet/api
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# --wasm : rendu skwasm (bien plus fluide sur Safari iOS), avec repli
# automatique sur CanvasKit/JS si le navigateur ne supporte pas WasmGC.
RUN flutter build web --release --wasm \
    --base-href "${BASE_HREF}" \
    --dart-define=API_BASE_URL="${API_BASE_URL}"

# Pré-compression : nginx sert directement les .gz (gzip_static), sans
# recompresser à chaque requête. Les .symbols ne servent qu'au debug.
RUN cd build/web \
    && find . -name '*.symbols' -delete \
    && find . -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.wasm' -o -name '*.json' \
        -o -name '*.html' -o -name '*.ttf' -o -name '*.otf' \) \
        -exec gzip -9 -k {} \;

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html/keepmydiet
