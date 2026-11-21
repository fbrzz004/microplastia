# Informe de inspección de seguridad — MicroplastIA

- Fecha: 14 de noviembre de 2026
- Alcance: backend (FastAPI), panel web administrativo (Angular), aplicación móvil (Flutter), repositorio y flujo de trabajo en Git
- Rama: `feat/security-hardening` (integrada en `dev`)
- Línea base: `main` `e4ed61c`, línea de integración `feature/reports` `8c75355`

## 1. Resumen ejecutivo

El proyecto ya contaba con bases sólidas: validación de JWT con comprobación del tipo de token,
hash de contraseñas con bcrypt, política de contraseñas, limitación de intentos de inicio de
sesión mediante el correo hasheado, hosts de confianza, listas de orígenes CORS, cabeceras de
seguridad, validación de MIME y decodificación de imágenes, y verificación de propiedad en
historial, resultados y reportes.

Esta inspección no encontró secretos confirmados en el repositorio ni rutas de inyección SQL o
de control de acceso roto. Las principales brechas eran el endurecimiento de la configuración,
algunos vectores de denegación de servicio, un canal lateral por tiempo de respuesta en el
inicio de sesión, el almacenamiento del token móvil en texto plano, la configuración de Android
para tráfico claro y copias de seguridad, y la ausencia de una política de seguridad de
contenido (CSP) en el panel administrativo.

Todos los hallazgos de prioridad alta y media están corregidos en esta rama. Los riesgos
residuales aceptados se detallan en la sección 5.

## 2. Hallazgos

| ID | Severidad | Área | Hallazgo | Estado |
|---|---|---|---|---|
| SEC-01 | Alta | Móvil | El JWT se guardaba en `shared_preferences` (texto plano). | Corregido: `flutter_secure_storage` con migración del token anterior y respaldo controlado. |
| SEC-02 | Media | Móvil | `android:usesCleartextTraffic="true"` en el manifiesto principal permitía HTTP en compilaciones de producción. | Corregido: solo HTTPS en release; tráfico claro habilitado únicamente en debug/profile. |
| SEC-03 | Media | Móvil | La copia de seguridad de Android estaba habilitada; los datos de la aplicación podían extraerse de un respaldo. | Corregido: `android:allowBackup="false"`. |
| SEC-04 | Media | Autenticación | El tiempo de respuesta del login difería entre correos existentes e inexistentes, lo que permitía enumerar cuentas. | Corregido: se verifica siempre un hash bcrypt de referencia. |
| SEC-05 | Media | Autenticación | Las contraseñas con muchos caracteres multibyte superaban el límite de 72 bytes de bcrypt y producían HTTP 500. | Corregido: validación de la longitud en bytes UTF-8. |
| SEC-06 | Media | Configuración del backend | Producción podía arrancar con un secreto JWT de ejemplo, hosts/orígenes locales o CORS comodín. | Corregido: validación de producción con fallo temprano al iniciar. |
| SEC-07 | Media | Configuración del backend | La documentación interactiva y OpenAPI podían quedar expuestas en producción. | Corregido: se deshabilitan siempre cuando `ENVIRONMENT=production`. |
| SEC-08 | Media | Carga de archivos | Las dimensiones de la imagen se validaban después de decodificarla por completo; una imagen muy comprimida con dimensiones enormes podía agotar la memoria. | Corregido: límite de píxeles de Pillow y validación de dimensiones desde la cabecera antes de decodificar. |
| SEC-09 | Baja | Reportes | Los nombres de los reportes tenían solo 24 bits de aleatoriedad, por lo que las URL públicas de `/static/reports` eran adivinables. | Corregido: nombres con 128 bits de aleatoriedad. |
| SEC-10 | Baja | API de análisis | La carga útil del análisis móvil no tenía límites para el número de partículas, el tiempo de procesamiento, el tamaño del desglose ni el número de detecciones. | Corregido: campos acotados y validador del desglose. |
| SEC-11 | Baja | Panel web | No existía Content Security Policy ni política de referencia. | Corregido: CSP restrictiva y cabecera `no-referrer`. |
| SEC-12 | Baja | Repositorio | Ramas de funcionalidad obsoletas y un flujo de trabajo de ramas mixto. | Corregido: rama de integración `dev`, jerarquía documentada y ramas obsoletas retiradas. |

## 3. Controles implementados

### Backend

- `backend/app/core/config.py`
  - `production_config_errors()` valida el secreto JWT, los hosts de confianza y los orígenes CORS.
  - `docs_available` deshabilita `/docs`, `/redoc` y `/openapi.json` en producción.
- `backend/app/main.py`
  - Ejecuta `validate_production_settings()` al iniciar.
  - Usa `docs_available` en lugar de `docs_enabled`.
- `backend/app/core/password_policy.py`
  - Rechaza contraseñas cuya codificación UTF-8 supere los 72 bytes.
- `backend/app/core/security.py`
  - Añade un hash bcrypt de referencia para que los fallos de autenticación tengan un costo constante.
- `backend/app/services/auth_service.py`
  - Verifica el hash de referencia cuando el correo no existe.
- `backend/app/core/file_validation.py`
  - Configura `Image.MAX_IMAGE_PIXELS`.
  - Valida ancho, alto y cantidad de píxeles desde la cabecera antes de decodificar.
  - Rechaza bombas de descompresión de Pillow.
- `backend/app/api/v1/endpoints/analyze.py`
  - `total_particles <= 100000`
  - `processing_time_ms <= 86400000`
  - como máximo 10 categorías de desglose, claves de hasta 50 caracteres y valores entre `0` y `100000`
  - como máximo 1000 detecciones
- `backend/app/services/report_service.py`
  - Los nombres de los reportes usan un `uuid4().hex` completo (128 bits).

### Panel web administrativo

- `admin_web/src/index.html`
  - La CSP restringe scripts, estilos, imágenes, marcos y conexiones de red.
  - `Referrer-Policy: no-referrer`.

### Móvil

- `mobile/lib/services/session_service.dart`
  - El JWT se guarda con `flutter_secure_storage`.
  - Migración única desde `shared_preferences`.
  - Respaldo solo cuando el almacenamiento seguro no está disponible, con un tiempo de espera de 1 segundo.
  - El cierre de sesión limpia ambos almacenes.
- `mobile/android/app/src/main/AndroidManifest.xml`
  - `usesCleartextTraffic="false"`, `allowBackup="false"`.
- `mobile/android/app/src/debug/AndroidManifest.xml`,
  `mobile/android/app/src/profile/AndroidManifest.xml`
  - Tráfico claro permitido únicamente en compilaciones locales de desarrollo.

## 4. Verificación

| Suite | Resultado |
|---|---|
| Backend (`pytest`, base SQLite de pruebas) | 56 superadas, 1 fallo conocido exclusivo de SQLite (`test_login_rate_limit`, fecha sin zona horaria) |
| Panel web (`npm test`) | 17 superadas |
| Panel web (`npm run build`) | Compilación correcta; solo advertencias previas de presupuesto de CSS |
| Móvil (`flutter analyze`) | Sin incidencias |
| Móvil (`flutter test`) | 12 superadas |

Comando del backend:

```bash
cd backend
DATABASE_URL=sqlite:////tmp/opencode/micro_test.db ./venv/bin/python -m pytest -q
```

Comandos del panel web:

```bash
cd admin_web
npm test -- --watch=false
npm run build
```

Comandos del móvil (Flutter SDK 3.47.7):

```bash
cd mobile
flutter analyze
flutter test
```

## 5. Riesgos residuales y recomendaciones

| Riesgo | Mitigación actual | Recomendación |
|---|---|---|
| `/static/uploads`, `/static/detections` y `/static/reports` son URL de capacidad de lectura pública. | Nombres aleatorios de 128 bits, sin listado de directorios y con `Cache-Control: no-store`. | Mover reportes e imágenes de muestras detrás de un endpoint autenticado o de URL firmadas de corta duración si pasan a ser sensibles. |
| El JWT del panel administrativo permanece en `localStorage`/`sessionStorage`. | La CSP limita las fuentes de script; el token dura 60 minutos. | Evaluar cookies HttpOnly, Secure y SameSite con protección CSRF. |
| El WebSocket móvil envía el JWT en la cadena de consulta. | Solo HTTPS/WSS y token de corta duración. | Cambiar a cabecera `Authorization` o a un saludo autenticado en el primer mensaje. |
| El APK de release se firma con la clave de depuración. | Ninguna. | Crear un almacén de claves privado de release, mantenerlo fuera de Git y configurar la firma en CI o de forma local. |
| La limitación de intentos de login es por correo, no por IP. | Bloqueo por cuenta e identificadores hasheados. | Añadir un límite por IP en el proxy inverso o en la aplicación. |
| No se usa una herramienta de migraciones al iniciar (`create_all`). | El esquema se crea desde los modelos. | Adoptar migraciones de Alembic para los cambios de producción. |
| El archivo local `backend/.env` contiene un secreto de desarrollo. | Está ignorado y nunca fue versionado. | Mantenerlo local y rotarlo si alguna vez sale de la máquina. |

No hay secretos versionados. `backend/.env.example` contiene únicamente valores de ejemplo.

## 6. Consolidación de ramas

- `dev` se creó desde `main` y avanzó por avance rápido hasta `feature/reports`.
- `main` no se modificó localmente; `origin/main` avanzó de forma independiente durante la inspección y está contenido en `dev`.
- Ramas retiradas tras la verificación: `feature/reports`, `feature/historial-analisis`,
  `fix/historial-esquema`, `origin/feature/flutter-views`, `origin/origin/feature/profile-flow`.
- Las etiquetas de archivo conservan las puntas retiradas: `archive/feature-historial-analisis`,
  `archive/fix-historial-esquema`.
- El flujo de trabajo quedó documentado en `README.md`: `main` ← `dev` ← `feat/*` / `fix/*`.
- La sincronización de muestras sin conexión (`feature/continuity`) quedó integrada en `dev` y
  en `origin/main` durante la revisión. Se conserva `origin/backup-feature-continuity-old` como
  respaldo de una iteración anterior; puede retirarse cuando se confirme que no aporta cambios
  únicos.

## 7. Nota de despliegue en producción

Con la nueva validación de arranque, producción no iniciará a menos que:

- `SECRET_KEY` sea un valor aleatorio de al menos 32 caracteres (no el marcador de ejemplo).
- `ALLOWED_HOSTS` incluya el host real de la API.
- `ALLOWED_ORIGINS` incluya únicamente orígenes HTTPS reales.

Este comportamiento de fallo temprano es intencional. Actualizar el entorno de producción antes
de desplegar esta rama.
