# ─── Etapa de build ───────────────────────────────────────────────────────
# Usamos python:3.11-slim para una imagen más liviana.
# "slim" = sin compiladores ni herramientas de sistema innecesarias.
# Peso aproximado: 60MB vs 900MB de la imagen completa.
FROM python:3.11-slim

# Evita que Python genere archivos .pyc (bytecode) en el contenedor.
# Beneficio: imagen más limpia, sin archivos temporales.
ENV PYTHONDONTWRITEBYTECODE=1

# Evita que Python bufferice stdout/stderr.
# Beneficio: los logs de uvicorn aparecen en tiempo real en `docker logs`.
ENV PYTHONUNBUFFERED=1

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# ─── Instalar dependencias ────────────────────────────────────────────────
# IMPORTANTE: copiamos requirements.txt ANTES que el código fuente.
# Razón: Docker cachea capas. Si el código cambia pero requirements.txt
# no, Docker reutiliza la capa de pip install (mucho más rápido en re-builds).
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ─── Copiar el código fuente ──────────────────────────────────────────────
COPY . .

# Puerto que expone la aplicación FastAPI
EXPOSE 8000

# ─── Comando de inicio ────────────────────────────────────────────────────
# host 0.0.0.0: acepta conexiones desde fuera del contenedor (necesario en Docker)
# port 8000: puerto estándar para FastAPI
# workers 1: en desarrollo usamos 1 worker; en producción se aumenta
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
