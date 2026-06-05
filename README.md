# 💰 SmartBudget+
> **Transforma tu relación con el dinero mediante tecnología inteligente.**


---

## 🚩 Problemática

En la actualidad, la gestión de las finanzas personales se ha vuelto una tarea compleja y abrumadora para la mayoría de las personas. Los principales desafíos identificados son:

1.  **Falta de Visibilidad Real**: Los usuarios suelen desconocer en qué se gasta exactamente su dinero hasta el final del mes.
2.  **Complejidad en el Seguimiento**: Las herramientas tradicionales (hojas de cálculo o apps genéricas) suelen ser tediosas de mantener, lo que lleva al abandono del hábito.
3.  **Metas Desconectadas**: No existe una relación clara entre el gasto diario y la capacidad de alcanzar metas financieras a largo plazo (viajes, ahorros, inversiones).
4.  **Ingreso de Datos Manual**: La mayoría de las aplicaciones requieren que el usuario escriba cada gasto, lo que genera fricción y eventual abandono.

---

## 💡 La Solución: SmartBudget+

**SmartBudget+** nace como una plataforma integral que combina simplicidad de uso con automatización en la captura de datos. Nuestra solución se centra en:

*   **Gestión de Presupuestos**: Control dinámico por categorías para evitar gastos innecesarios.
*   **Seguimiento de Gastos en Tiempo Real**: Registro ágil y categorización automática.
*   **Metas Inteligentes**: Establecimiento de objetivos con seguimiento de progreso visual.
*   **SmartScore**: Un indicador de "Salud Financiera" que puntúa el comportamiento del usuario.
*   **Lectura de Documentos (OCR)**: En lugar de ingresos manuales complejos, permitimos la **extracción de datos desde facturas y recibos en imágenes y PDFs** para automatizar el registro de gastos y asegurar que ningún detalle se pierda.

---

## 🛠 Tecnologías Utilizadas

El proyecto utiliza un stack moderno, escalable y robusto:

### **Backend**
*   **Framework**: [FastAPI](https://fastapi.tiangolo.com/) (Python 3.10+) para una API de alto rendimiento.
*   **Base de Datos**: [MySQL](https://www.mysql.com/) gestionado mediante **SQLAlchemy** (ORM).
*   **Migraciones**: [Alembic](https://alembic.sqlalchemy.org/) para el control de versiones de la base de datos.
*   **Procesamiento de Documentos**: Integración de librerías de **OCR y extracción de datos** (Tesseract, PDFPlumber/PyMuPDF) para la lectura automática de archivos.

### **Infraestructura & DevOps**
*   **Contenerización**: [Docker](https://www.docker.com/) y **Docker Compose** para un despliegue consistente en cualquier entorno.
*   **Administración**: Adminer integrado para la gestión visual de la base de datos en desarrollo.

---

## 📂 Estructura del Proyecto

El proyecto está organizado en una arquitectura de microservicios contenida en un único repositorio (Monorepo):

```text
Herramientas_Desarrollo_Smartbudget/
├── backend/                    # 🚀 Servidor de API (FastAPI)
│   ├── api/                    # Controladores, esquemas y rutas
│   ├── core/                   # Configuración global y seguridad (JWT)
│   ├── db/                     # Modelos de base de datos y conexión
│   ├── alembic/                # Gestión de migraciones de base de datos
│   ├── tests/                  # Pruebas automatizadas del servidor
│   └── Dockerfile              # Configuración de imagen para el backend
├── docs/                       # Recursos de documentación
├── docker-compose.yml          # Orquestador de servicios (BD, API, Front)
└── .env.example                # Plantilla de variables de entorno
```

---

## 📅 Planificación (Roadmap)

El desarrollo se divide en 5 fases estratégicas:

### **Fase 1: Cimientos & DevOps** (Finalizado ✅)
*   Configuración del entorno Docker (Backend, Frontend, BD).
*   Estructura base del proyecto y conectividad.

### **Fase 2: Núcleo de Gestión (MVP)** (En Curso 🏗️)
*   Implementación de Autenticación (JWT).
*   API de Presupuestos y Gastos.
*   Primeras vistas en Flutter para registro de transacciones.

### **Fase 3: Visualización & Metas** (Próximamente 🔜)
*   Módulo de Metas Financieras.
*   Gráficos dinámicos y reportes mensuales.
*   Sincronización completa Frontend-Backend.

### **Fase 4: Automatización (OCR)**
*   Implementación del motor de lectura de Imágenes y PDFs.
*   Algoritmo de categorización automática basada en la lectura de documentos.
*   Cálculo del indicador **SmartScore**.

### **Fase 5: Optimización & Lanzamiento**
*   Refactorización y optimización de consultas.
*   Pruebas unitarias y de integración (Pytest).
*   Preparación para entorno de producción.

---

## 🚀 Cómo Correr el Proyecto

Para levantar el entorno completo de desarrollo, sigue estos pasos:

### 1. Requisitos Previos
*   Tener instalado **Docker** y **Docker Compose**.
*   Clonar este repositorio.

### 2. Configuración de Variables
Copia el archivo de ejemplo y configura tus claves (especialmente la `JWT_SECRET_KEY`):
```bash
# Windows
copy .env.example .env
# Linux/Mac
cp .env.example .env
```

### 3. Levantar con Docker
Desde la raíz del proyecto, ejecuta:
```bash
docker compose up --build -d
```

### 4. Acceso a los Servicios
Una vez finalizado, puedes acceder a:
*   **API Backend**: [http://localhost:8000](http://localhost:8000) (Documentación en `/docs`)
*   **Gestor BD (Adminer)**: [http://localhost:8081](http://localhost:8081)

---

> 💡 **Documentación Detallada**: Para una guía paso a paso con resolución de problemas, visita las **[Instrucciones de Docker](INSTRUCCIONES_DOCKER.md)**.

---

*Desarrollado con ❤️ para mejorar la salud financiera de las personas.*