# Etapa 1: construir Flutter Web con la misma versión que usas localmente
# Tu entorno local está en Flutter 3.35.5, usamos la misma imagen
FROM ghcr.io/cirruslabs/flutter:3.35.5 AS build

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos todo el proyecto al contenedor
COPY . .

# Habilitamos el soporte web (por si no está configurado)
RUN flutter config --enable-web

# Descargamos dependencias del proyecto
RUN flutter pub get

# Build de producción para Web
RUN flutter build web --release --base-href=/
# o incluso solo:
# RUN flutter build web --release

# Etapa 2: servir los estáticos con Nginx
FROM nginx:alpine

# Copiamos el build web generado en la etapa anterior
COPY --from=build /app/build/web /usr/share/nginx/html

# Exponemos el puerto HTTP
EXPOSE 80

# Arrancamos nginx en foreground
CMD ["nginx", "-g", "daemon off;"]
