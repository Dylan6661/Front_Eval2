# =====================================================
# DOCKERFILE - Frontend Flask (Multi-Stage Build)
# Proyecto: Sistema de Gestión de Usuarios
# =====================================================

# ---------- Etapa 1: Dependencias ----------
FROM python:3.11-slim AS builder

WORKDIR /app

# Copiar solo requirements para aprovechar cache de capas
COPY requirements.txt .

# Instalar dependencias en un directorio virtual
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Etapa 2: Producción ----------
FROM python:3.11-slim AS production

# Metadata del contenedor
LABEL maintainer="Innovatech Chile"
LABEL description="Frontend Flask - Sistema de Gestión de Usuarios"

# Crear usuario no root por seguridad (mínimo privilegio)
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

WORKDIR /app

# Copiar dependencias instaladas desde la etapa builder
COPY --from=builder /install /usr/local

# Copiar código fuente de la aplicación
COPY --chown=appuser:appuser . .

# Eliminar archivos innecesarios en producción
RUN rm -f .env .env.example Dockerfile .dockerignore docker-compose.yml 2>/dev/null || true

# Variables de entorno por defecto
ENV PORT=5000
ENV DEBUG=False
ENV FLASK_ENV=production

# Exponer el puerto del frontend
EXPOSE 5000

# Cambiar a usuario no root
USER appuser

# Comando de inicio
CMD ["python", "app.py"]
