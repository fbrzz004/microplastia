# MicroplastIA

Aplicación móvil orientada al análisis de imágenes de microscopía para apoyar la detección y clasificación de partículas de microplásticos mediante inteligencia artificial.

## Estado del proyecto

**En desarrollo.**

El proyecto ya integra el modelo YOLOv8n para el análisis de imágenes, el registro e inicio de sesión con JWT, y el almacenamiento de cada análisis en el historial del usuario. La generación de reportes a partir de los análisis seleccionados está pendiente.

## Tecnologías

* **Frontend móvil:** Flutter y Dart.
* **Backend:** Python y FastAPI.
* **Servidor de desarrollo:** Uvicorn.
* **Modelo de detección previsto:** YOLOv8n.
* **Control de versiones:** Git y GitHub.

## Requisitos previos

* Git.
* Flutter SDK y Dart.
* Python 3.10 o una versión compatible con las dependencias del backend.
* Un emulador Android o dispositivo compatible para ejecutar la aplicación móvil.

## Configuración del backend

Desde la raíz del repositorio, ingresa a la carpeta del backend:

```bash
cd backend
```

Crea y activa un entorno virtual.

En Windows PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Instala las dependencias:

```powershell
python -m pip install -r requirements.txt
```

Si el proyecto requiere variables de entorno, crea un archivo `.env` local a partir de `.env.example` y configura los valores necesarios. No subas el archivo `.env` al repositorio.

Inicia el servidor:

```powershell
python -m uvicorn app.main:app --reload
```

El backend estará disponible normalmente en:

`http://127.0.0.1:8000`

### Endpoints disponibles

| Método | Endpoint                | Propósito                                                                 |
| ------ | ----------------------- | ------------------------------------------------------------------------- |
| GET    | `/api/v1/health`        | Verificar el estado de la API.                                            |
| POST   | `/api/v1/auth/register` | Registrar un usuario.                                                     |
| POST   | `/api/v1/auth/login`    | Iniciar sesión y obtener el token JWT.                                    |
| POST   | `/api/v1/analyze`       | Analizar una imagen, guardarla en el historial y devolver las detecciones. |
| GET    | `/api/v1/history`       | Listar los análisis del usuario autenticado.                              |
| GET    | `/api/v1/results/{id}`  | Obtener el detalle de un análisis guardado.                               |

Los endpoints de análisis e historial requieren el encabezado
`Authorization: Bearer <token>` obtenido en el inicio de sesión.

Documentación interactiva:

`http://127.0.0.1:8000/docs`

Para detener el servidor, utiliza `Ctrl + C` en la terminal.

## Configuración de la aplicación móvil

Abre una segunda terminal desde la raíz del repositorio:

```bash
cd mobile
flutter pub get
flutter analyze
flutter run
```

Ejecuta la aplicación en un emulador o dispositivo compatible.

### Dirección del backend

La URL base depende del entorno donde se ejecuta Flutter:

* **Emulador Android:** `http://10.0.2.2:8000`
* **Flutter Web y escritorio (Linux/Windows/macOS):** `http://127.0.0.1:8000`
* **Dispositivo Android físico:** utiliza la dirección IP local de la computadora donde se ejecuta FastAPI, con ambos dispositivos conectados a una red que permita la comunicación.

La URL se puede sobrescribir al compilar o ejecutar con `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://172.16.58.141:8000
```

La configuración de la URL debe mantenerse centralizada en el archivo de configuración del frontend. Para Flutter Web, también puede ser necesario configurar CORS en FastAPI.

## Flujo previsto

1. Acceso a la aplicación mediante la pantalla de inicio de sesión.
2. Navegación al inicio y selección de una nueva muestra.
3. Selección y envío de una imagen al backend.
4. Procesamiento de la imagen mediante el modelo de detección.
5. Presentación de resultados y consulta del historial.
6. Selección de análisis para generar reportes (pendiente).

La generación de reportes es la funcionalidad pendiente del flujo.

## Buenas prácticas para contribuir

* Crear una rama propia para cada funcionalidad.
* Mantener los cambios organizados y realizar commits descriptivos.
* Ejecutar `flutter analyze` antes de enviar cambios del frontend.
* Verificar el funcionamiento del backend antes de enviar cambios de la API.
* No subir contraseñas, tokens, archivos `.env`, datasets completos ni pesos de modelos al repositorio.
* Documentar nuevas variables de entorno en `.env.example`, usando valores de ejemplo que no sean secretos.

