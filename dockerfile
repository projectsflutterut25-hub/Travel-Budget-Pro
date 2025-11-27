# Etapa 1: Build de Flutter Web dentro del contenedor
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copiamos todo el código del proyecto
COPY . .

# Habilitamos web (por si acaso) y resolvemos dependencias
RUN flutter config --enable-web
RUN flutter pub get

# Build de producción de Flutter Web
RUN flutter build web --release

# Etapa 2: Nginx sirviendo la app
FROM nginx:alpine

# Quitamos config por defecto de nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copiamos nuestra configuración
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiamos la build generada en la etapa anterior
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
