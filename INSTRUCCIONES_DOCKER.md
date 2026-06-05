# 🚀 Guía de Configuración con Docker - SmartBudget+

Esta guía detalla los pasos necesarios para que cualquier miembro del equipo pueda levantar el entorno completo de desarrollo (Backend, Frontend y Base de Datos) utilizando Docker.

## 🛠 Requisitos Previos

Asegúrate de tener instalado lo siguiente:
1. **Docker Desktop**: [Descargar aquí](https://www.docker.com/products/docker-desktop/)
2. **Git**: Para clonar el repositorio.
3. **Python** (Opcional): Para generar la clave secreta de seguridad.

---

## 📥 Paso 1: Clonar el Repositorio

Si aún no lo tienes, clona el proyecto en tu máquina local:
```bash
git clone https://github.com/RobertoC1006/Herramientas_Desarrollo_Smartbudget.git
cd Herramientas_Desarrollo_Smartbudget
```

---

## ⚙️ Paso 2: Configuración de Variables de Entorno

El sistema utiliza un archivo `.env` para manejar credenciales y configuraciones sensibles.

1. **Crear el archivo `.env`**:
   Copia el archivo de ejemplo proporcionado:
   ```bash
   # En Mac o Linux:
   cp .env.example .env

   # En Windows (PowerShell):
   copy .env.example .env
   ```

2. **Generar la `JWT_SECRET_KEY`**:
   Esta clave es necesaria para la autenticación. Genera una nueva ejecutando:
   ```bash
   python -c "import secrets; print(secrets.token_hex(32))"
   ```
   Copia el resultado y pégalo en tu archivo `.env` en la línea:
   `JWT_SECRET_KEY=tu_clave_generada_aqui`

3. **Configurar OpenAI**:
   Pega tu API Key de OpenAI en la variable:
   `OPENAI_API_KEY=sk-XXXX...`

4. **Revisar Base de Datos** (Opcional):
   Por defecto, el archivo `.env.example` ya viene configurado para conectar con el servicio de MySQL de Docker. Solo cambia las contraseñas si lo deseas.

---

## 🏗 Paso 3: Levantar el Proyecto

Desde la carpeta raíz del proyecto, ejecuta el siguiente comando:

```bash
docker compose up --build -d
```

> **Nota:** La primera vez tardará unos minutos mientras descarga las imágenes y compila el frontend de Flutter. Las siguientes veces será mucho más rápido.

---

## 🌐 Servicios Disponibles

Una vez que los contenedores estén corriendo, podrás acceder a:

| Servicio | URL | Descripción |
| :--- | :--- | :--- |
| **Backend** | [http://localhost:8000](http://localhost:8000) | API FastAPI. Visita `/docs` para la documentación interactiva. |
| **Frontend** | [http://localhost:3001](http://localhost:3001) | Aplicación Flutter Web / PWA. |
| **Adminer** | [http://localhost:8081](http://localhost:8081) | Interfaz web para gestionar la base de datos MySQL. |

### Datos de acceso para Adminer:
- **Motor:** `MySQL`
- **Servidor:** `mysql` (es el nombre del servicio en Docker)
- **Usuario:** El valor de `MYSQL_USER` en tu `.env` (default: `sb_user`)
- **Contraseña:** El valor de `MYSQL_PASSWORD` en tu `.env`
- **Base de datos:** `smartbudget_db`

---

## 💾 Acceso Externo a la Base de Datos

Si prefieres usar una herramienta como **DBeaver, MySQL Workbench o TablePlus**, utiliza estos datos:
- **Host:** `localhost`
- **Puerto:** `3307` (Este puerto redirige al 3306 interno de Docker)
- **Usuario/Password:** Los mismos de tu `.env`.

---

## 🔍 Comandos Útiles de Docker

*   **Ver logs en tiempo real**: `docker compose logs -f`
*   **Detener todo**: `docker compose down`
*   **Limpiar y reiniciar base de datos (BORRA TODO)**: `docker compose down -v`
*   **Reiniciar un solo servicio (ej. backend)**: `docker compose restart backend`

---

> 💡 **Tip para el equipo:** Si realizas cambios en `db/models.py`, la base de datos de Docker no se actualizará sola. Debes usar el comando **"Limpiar y reiniciar"** para que MySQL se reconstruya con las nuevas tablas.

---

✨ **¡Listo!** Si tienes algún error, asegúrate de que no haya otro servicio usando los puertos 8000, 3001 o 3307 en tu computadora.
