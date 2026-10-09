# MicroplastIA

Aplicación móvil orientada al análisis de imágenes de microscopía para apoyar la detección y clasificación de partículas de microplásticos mediante inteligencia artificial.

## Estado del proyecto

**En desarrollo.**

Actualmente, el proyecto cuenta con una estructura inicial para la aplicación móvil en Flutter y el backend en FastAPI. La navegación entre las pantallas principales está implementada y el endpoint de salud del backend ha sido verificado.

La integración del modelo YOLOv8n, el envío real de imágenes y el almacenamiento de los resultados están pendientes de implementación o validación.

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

| Método | Endpoint          | Propósito                                                                   |
| ------ | ----------------- | --------------------------------------------------------------------------- |
| GET    | `/api/v1/health`  | Verificar el estado de la API.                                              |
| POST   | `/api/v1/analyze` | Endpoint de análisis en desarrollo; la respuesta actual puede ser simulada. |

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
* **Flutter Web en la misma computadora:** `http://127.0.0.1:8000`
* **Dispositivo Android físico:** utiliza la dirección IP local de la computadora donde se ejecuta FastAPI, con ambos dispositivos conectados a una red que permita la comunicación.

La configuración de la URL debe mantenerse centralizada en el archivo de configuración del frontend. Para Flutter Web, también puede ser necesario configurar CORS en FastAPI.

## Flujo previsto

1. Acceso a la aplicación mediante la pantalla de inicio de sesión.
2. Navegación al inicio y selección de una nueva muestra.
3. Selección y envío de una imagen al backend.
4. Procesamiento de la imagen mediante el modelo de detección.
5. Presentación de resultados y consulta del historial.

Los pasos que dependen del modelo, del envío real de imágenes y del almacenamiento todavía requieren implementación y pruebas.

## Buenas prácticas para contribuir

* Crear una rama propia para cada funcionalidad.
* Mantener los cambios organizados y realizar commits descriptivos.
* Ejecutar `flutter analyze` antes de enviar cambios del frontend.
* Verificar el funcionamiento del backend antes de enviar cambios de la API.
* No subir contraseñas, tokens, archivos `.env`, datasets completos ni pesos de modelos al repositorio.
* Documentar nuevas variables de entorno en `.env.example`, usando valores de ejemplo que no sean secretos.

