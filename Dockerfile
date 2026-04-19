# Etapa 1: Compilación
FROM debian:latest AS build-env

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y curl git unzip

# Descargar e instalar Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Ejecutar doctor y habilitar web
RUN flutter doctor
RUN flutter config --enable-web

# Copiar los archivos del proyecto al contenedor
RUN mkdir /app/
COPY . /app/
WORKDIR /app/

# Limpiar y compilar la versión Web
RUN flutter pub get
RUN flutter build web

# Etapa 2: Servidor para mostrar la web
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Exponer el puerto que usa Railway
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
