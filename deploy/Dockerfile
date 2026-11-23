# Imagen de la aplicacion (decisiones 12.6 y G1). Se construye desde la raiz del repositorio:
#   docker build -f deploy/Dockerfile -t enlace-express .
# Multietapa: compila el frontend y el backend y deja solo un JRE 21 con el jar. Las imagenes base son
# multiarquitectura (x86 y ARM). Las pruebas no se corren aqui: ya corren en la CI.

# ---- 1. Frontend (Vite y TypeScript); la salida va a backend/src/main/resources/static
FROM node:22.23.5-alpine AS frontend
WORKDIR /repo/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY frontend/ ./
RUN npm run build

# ---- 2. Backend (Maven con JDK 21), con el frontend compilado como recursos estaticos
FROM maven:3.9.9-eclipse-temurin-21 AS backend
WORKDIR /repo/backend
COPY backend/pom.xml ./
RUN mvn -B -q dependency:go-offline
COPY backend/src ./src
COPY --from=frontend /repo/backend/src/main/resources/static ./src/main/resources/static
RUN mvn -B -q -DskipTests package

# ---- 3. Imagen final: JRE 21 sin privilegios, zona horaria America/Bogota (decision C6)
FROM eclipse-temurin:21.0.13_9-jre-alpine
RUN apk add --no-cache tzdata \
    && addgroup -S enlace && adduser -S -G enlace -h /app enlace
ENV TZ=America/Bogota \
    JAVA_TOOL_OPTIONS="-Duser.timezone=America/Bogota"
WORKDIR /app
COPY --from=backend /repo/backend/target/enlace-express-*.jar /app/app.jar
USER enlace
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=40s --retries=5 \
    CMD wget -q -O /dev/null http://localhost:8080/api/salud || exit 1
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
