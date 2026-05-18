# ─── Étape 1 : Build Flutter Web ───────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.19.6 AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=http://localhost:8000/api/v1

# ─── Étape 2 : Servir avec Nginx ──────────────────────────────────
FROM nginx:1.25-alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx-web.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
