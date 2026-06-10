# Informe de Prototipado Rápido y Pruebas de Concepto - SmartBudget+

## Índice General

1. **Prototipado Rápido y Pruebas de Concepto**
   - 1.1. Descripción de los prototipos
     - 1.1.1. Prototipo A (Diseño Visual en Figma)
     - 1.1.2. Prototipo B (Aplicación Móvil Interactiva en Flutter y API)
   - 1.2. Hallazgos de las pruebas iniciales
     - 1.2.1. Experiencia de Usuario y Usabilidad (UX/UI)
     - 1.2.2. Validación Técnica y Rendimiento
     - 1.2.3. Resumen de Evolución del Producto y Próximos Pasos

4. **Diseño de Interfaces y Visualización de Conceptos**
   - 4.1. Principios de diseño aplicados
   - 4.2. Pantallas principales del prototipo
   - 4.3. Coherencia entre diseño e identidad del producto

---

## 1. Prototipado Rápido y Pruebas de Concepto

El desarrollo de **SmartBudget+** se ha estructurado bajo un enfoque ágil centrado en el usuario. Para validar de manera iterativa los flujos de interacción, la propuesta estética y la viabilidad técnica, se desarrollaron dos prototipos complementarios: uno visual y estático (Prototipo A en Figma) y otro funcional e interactivo (Prototipo B en Flutter con backend en FastAPI). 

El foco principal de validación en esta etapa ha sido la **simplificación del registro de gastos a través de tecnología OCR (Reconocimiento Óptico de Caracteres)**, buscando resolver la principal barrera de adopción de las aplicaciones financieras: la fricción del ingreso de datos manual.

---

### 1.1. Descripción de los prototipos

#### 1.1.1. Prototipo A (Diseño Visual en Figma)
El **Prototipo A** representa la definición conceptual y visual de alta fidelidad de la aplicación. Su objetivo fue alinear el lenguaje visual, establecer la marca gráfica y definir la jerarquía de la información sin la complejidad de la lógica de programación.

*   **Identidad Visual y Diseño**: Se definió una paleta de colores basada en tonalidades verdes y blancas para transmitir salud financiera, crecimiento y tranquilidad. Se utilizaron gradientes suaves, sombreados con profundidad sutil y esquinas muy redondeadas para otorgar un aspecto moderno y premium.
*   **Vistas Principales Diseñadas**:
    1.  **Dashboard (Inicio)**: Presenta de forma clara el balance disponible del usuario dentro de una tarjeta verde dominante, seguida por tarjetas independientes de ingresos y gastos. Destaca una tarjeta central de **SmartScore** (índice de salud financiera) con barra de progreso circular o de línea, su estado ("Excelente") y una recomendación automatizada.
    2.  **Registro Manual (Agregar)**: Formulario optimizado mediante una tarjeta flotante que agrupa la selección de categoría, monto y una descripción opcional, minimizando los campos para reducir la fatiga de entrada.
    3.  **Metas de Ahorro (Metas)**: Tarjeta con gradiente azul representativa de metas específicas (ej. "Playa" con objetivo de S/ 500.00), mostrando porcentaje de avance, monto restante y el botón de acción directa "+ Abonar a esta meta".
    4.  **Análisis Financiero (Análisis)**: Sección que muestra la distribución de gastos a través de un gráfico de pastel dinámico.

---

#### 1.1.2. Prototipo B (Aplicación Móvil Interactiva en Flutter y API)
El **Prototipo B** es el entorno de software funcional desarrollado sobre el monorepo. Su propósito es actuar como una prueba de concepto interactiva y real que conecta la interfaz móvil con la lógica del negocio en el servidor.

*   **Arquitectura y Tecnologías**:
    *   **Frontend (Flutter)**: Implementa las pantallas diseñadas en el Prototipo A, enriquecidas con transiciones animadas avanzadas (`flutter_animate`), widgets personalizados y gráficos interactivos (`fl_chart`).
    *   **Backend (FastAPI & MySQL)**: API en Python que gestiona la base de datos relacional y realiza los cálculos algorítmicos.
*   **Evolución e Innovación Funcional Clave (Lectura OCR Inteligente)**:
    La principal diferencia operativa y valor añadido en el Prototipo B es la **pantalla de escaneo de comprobantes por Inteligencia Artificial (`scan_receipt_screen.dart`)**:
    1.  **Captura Flexible**: El usuario puede tomar una fotografía directa a su ticket de compra utilizando la cámara del celular o seleccionar una imagen desde su galería.
    2.  **Procesamiento Inteligente**: La aplicación envía la imagen al backend, donde un motor de análisis OCR extrae automáticamente datos críticos como:
        *   El **Comercio o establecimiento** emisor.
        *   La **Fecha** de la transacción.
        *   El **Monto total** cobrado.
        *   La **Categoría** estimada del gasto (comida, transporte, hogar, etc.).
        *   Una **Descripción** simplificada del consumo.
    3.  **Flujo de Verificación Integrado**: Tras el procesamiento, el prototipo redirige al usuario a un formulario interactivo precargado con la información extraída. Esto le permite verificar y, de ser necesario, corregir los datos antes de guardarlos definitivamente en su presupuesto actual, reduciendo el proceso a solo un par de toques.
    4.  **Persistencia Real**: Sincronización completa con la base de datos relacional para reflejar el gasto y actualizar automáticamente el saldo disponible y el SmartScore del usuario.

---

### 1.2. Hallazgos de las pruebas iniciales

Las pruebas de usabilidad y rendimiento con usuarios reales utilizando ambos prototipos arrojaron hallazgos clave:

#### 1.2.1. Experiencia de Usuario y Usabilidad (UX/UI)
*   **Eliminación Radical del Abandono (Foco OCR)**: En las pruebas del Prototipo A, aunque los usuarios valoraron positivamente la simplicidad visual del registro manual, admitieron que ingresar cada gasto a mano suele provocar el abandono de este tipo de apps en el mediano plazo. En contraste, en el Prototipo B, la función de escaneo OCR fue catalogada como **indispensable y altamente atractiva**, eliminando la fricción y automatizando la tarea tediosa del registro de transacciones.
*   **Gestión del Feedback Visual en Tiempos de Espera**: Dado que el análisis de la imagen y la extracción de datos por IA toma de 2 a 3 segundos, los usuarios valoraron la presencia de animaciones dinámicas que informan el estado actual del proceso (*"Subiendo comprobante..."*, *"Analizando estructura..."*, *"IA está extrayendo datos de compra..."*). Esto mantiene al usuario informado y evita la sensación de bloqueo en la aplicación.

#### 1.2.2. Validation Técnica y Rendimiento
*   **Importancia del Formulario de Verificación**: Las pruebas iniciales demostraron que la precisión de la IA para catalogar comercios y clasificar categorías automáticamente es muy alta, pero no infalible (por ejemplo, compras en un supermercado que pueden ser tanto alimentos como vestimenta). El formulario interactivo post-escaneo en el Prototipo B demostró ser un paso de validación obligatorio y bien aceptado por los usuarios para garantizar la calidad de sus reportes.
*   **Optimización de Imágenes en el Frontend**: Se identificó que para agilizar las peticiones al servidor, la aplicación en Flutter debe reducir ligeramente la calidad de las fotos capturadas a un 85% antes de subirlas. Esto optimiza el ancho de banda y acelera el procesamiento OCR sin sacrificar la legibilidad de los textos para el motor de IA.

#### 1.2.3. Resumen de Evolución del Producto y Próximos Pasos
*   La transición de un diseño estático (Prototipo A) a un desarrollo interactivo (Prototipo B) validó que la propuesta de valor de SmartBudget+ reside en su capacidad de automatizar la captura de datos.
*   **Próximos pasos prioritarios**:
    *   Refinar el motor OCR del backend para mejorar la precisión de clasificación en transacciones con múltiples artículos.
    *   Diseñar y estructurar la lógica técnica de un simulador predictivo para incorporarlo en futuras fases de pruebas, una vez definido su alcance de negocio óptimo.

---
---

## 4. Diseño de Interfaces y Visualización de Conceptos

La interfaz de **SmartBudget+** ha sido concebida bajo premisas estéticas y de interacción contemporáneas, traduciendo conceptos financieros tradicionalmente áridos en una experiencia interactiva atractiva y de alta usabilidad.

### 4.1. Principios de diseño aplicados

En el diseño y desarrollo de las interfaces (Prototipos A y B) se aplicaron principios fundamentales de diseño y usabilidad (heurísticas de Jakob Nielsen):

*   **Claridad y Minimalismo (Aesthetic and Minimalist Design)**: Las interfaces evitan la sobrecarga de información. Se hace un uso inteligente del espacio en blanco para estructurar los elementos y agrupar la información en tarjetas visuales independientes.
*   **Visibilidad del Estado del Sistema (Visibility of System Status)**: En el prototipo interactivo (B), las micro-animaciones en los botones, transiciones de carga inteligentes durante la lectura OCR y cambios dinámicos de colores indican claramente al usuario qué proceso está ejecutando la aplicación en cada instante.
*   **Flexibilidad y Eficiencia de Uso (Flexibility and Efficiency of Use)**: Se ofrecen dos caminos para registrar gastos: una vía automatizada y veloz (Escaneo OCR) para los tickets del día a día, y una vía manual estructurada (Registro Manual) para cuando se requiera ingresar un gasto específico sin comprobante físico.
*   **Consistencia y Estándares (Consistency and Standards)**: La navegación principal se mantiene visible y fija en la parte inferior mediante un menú de cinco pestañas estándar (Inicio, Agregar, Metas, Análisis, Perfil). Asimismo, los colores y la tipografía son consistentes a lo largo de todas las pantallas, manteniendo las mismas convenciones visuales (ej. verde para ingresos y rojo para gastos).
*   **Prevención y Tolerancia a Errores (Error Prevention & Recovery)**: En el flujo de OCR, el usuario no guarda los datos directamente tras la lectura. Se presenta un paso intermedio (pantalla de verificación) donde puede corregir cualquier error de lectura del motor de IA antes de que afecte su balance real.

---

### 4.2. Pantallas principales del prototipo

Las pantallas clave que estructuran el prototipo interactivo de SmartBudget+ y definen el recorrido del usuario son:

1.  **Dashboard / Inicio**:
    *   **Cabecera de Balance Principal**: Una franja verde esmeralda destacada que muestra de inmediato el dinero disponible actual (`S/ 1950.00`) para generar visibilidad financiera en el primer segundo de uso.
    *   **Tarjetas de Resumen Mensual**: Separación visual de ingresos (+S/ 2000.00) y gastos (-S/ 50.00) para facilitar el control de flujos de caja.
    *   **Módulo SmartScore**: Muestra el indicador principal de salud financiera con una escala numérica (98/100) y un mensaje motivacional e instructivo.
2.  **Registro Manual (Agregar)**:
    *   Diseño tipo tarjeta flotante que se superpone a un fondo limpio para centrar la atención en la tarea.
    *   Campos limpios con dropdown de selección de categoría y teclado numérico adaptado, optimizados para completarse en menos de 10 segundos.
3.  **Escaneo de Comprobantes (OCR)**:
    *   Flujo limpio con botones prominentes para acceder a la cámara y galería del dispositivo.
    *   Contiene animaciones activas e instructivas sobre cómo la IA procesa y segmenta la información de la imagen de forma inteligente.
4.  **Mis Metas (Metas)**:
    *   Uso de tarjetas flotantes con gradientes degradados en color azul que simbolizan objetivos a largo plazo (ej. "Playa").
    *   Incluye barras de progreso de alta legibilidad que indican de forma porcentual e interactiva cuánto le falta al usuario para alcanzar su meta.
5.  **Distribución de Gastos (Análisis)**:
    *   Presenta la información consolidada en un gráfico circular dinámico y limpio, donde cada categoría de gasto se diferencia por un color específico, facilitando la comprensión de los hábitos de consumo.

---

### 4.3. Coherencia entre diseño e identidad del producto

La coherencia visual de **SmartBudget+** está intrínsecamente ligada a su propuesta de valor: democratizar las finanzas personales mediante tecnología inteligente y sin estrés.

*   **Psicología del Color y Calma Financiera**: Se utiliza el verde esmeralda como color primario del producto. En psicología del color, el verde no solo se asocia con el dinero y el crecimiento, sino también con la tranquilidad y la estabilidad. Esto ayuda a disminuir la ansiedad que a menudo acompaña al monitoreo de presupuestos.
*   **Innovación Visual y Estética Premium (Glassmorphism)**: Al implementar efectos visuales modernos de desenfoque de fondo y transparencias tipo cristal ("Glassmorphism") en el Prototipo B, la app se distancia de las herramientas financieras corporativas y aburridas (como las hojas de cálculo). Esto posiciona a SmartBudget+ como una plataforma innovadora, tecnológica, y orientada al público joven y digital.
*   **Gamificación del Ahorro (SmartScore y Metas)**: La identidad de SmartBudget+ no es la de un simple "historial de gastos", sino la de un consejero financiero activo. Esto se traduce visualmente al ubicar el SmartScore en la parte central del inicio, impulsando al usuario a "jugar" para mantener su puntaje en un nivel excelente (color verde brillante), reforzando la identidad de acompañamiento dinámico.
*   **Sensación de Inteligencia en Tiempo Real**: Las transiciones limpias y las respuestas inmediatas del flujo OCR refuerzan la promesa de marca de ser una aplicación "inteligente" impulsada por tecnología avanzada de extracción de datos, alineando el diseño del flujo con las expectativas técnicas del usuario.
