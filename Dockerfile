FROM ghcr.io/cirruslabs/flutter:3.22.2 AS build
WORKDIR /app

# Аргументы/переменные для --dart-define
ARG API_BASE_URL
ARG FIREBASE_API_KEY
ARG FIREBASE_AUTH_DOMAIN
ARG FIREBASE_PROJECT_ID
ARG FIREBASE_APP_ID
ARG FIREBASE_MESSAGING_SENDER_ID
ARG FIREBASE_STORAGE_BUCKET

# Кэш зависимостей
COPY pubspec.* ./
RUN flutter pub get

# Копия исходников и повторная установка зависимостей (на случай обновлений)
COPY . .
RUN flutter pub get

# Сборка web (canvaskit обычно стабильнее для сложной графики; можешь убрать флаг)
RUN flutter build web --release --web-renderer canvaskit \
  --dart-define=API_BASE_URL=${API_BASE_URL} \
  --dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY} \
  --dart-define=FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN} \
  --dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID} \
  --dart-define=FIREBASE_APP_ID=${FIREBASE_APP_ID} \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID} \
  --dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}

# --- runtime: Nginx ---
FROM nginx:alpine
# SPA fallback + кэш статики
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

# Healthcheck (страница должна отдаваться)
HEALTHCHECK --interval=10s --timeout=5s --retries=6 CMD \
  wget -qO- http://127.0.0.1:80/index.html >/dev/null || exit 1