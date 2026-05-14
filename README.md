# Frontend - Aplicación Web con Flask 🖥️

## Descripción

Frontend desarrollado en **Python** con el framework **Flask**. Proporciona una interfaz web completa para la gestión de usuarios, con comunicación RESTful con el backend API. Esta aplicación se ejecuta en un contenedor Docker desplegado en una instancia **EC2 pública** de AWS.

---

## Arquitectura de Contenedorización

```
┌─────────────────────────────────────┐
│         EC2 Pública (Frontend)      │
│                                     │
│   ┌─────────────────────────────┐   │
│   │   Contenedor: Flask App     │   │
│   │   Puerto: 5000              │   │
│   │   Usuario: appuser (no root)│   │
│   └─────────────┬───────────────┘   │
│                 │                    │
└─────────────────┼────────────────────┘
                  │ HTTP (puerto 3000)
                  ▼
┌─────────────────────────────────────┐
│       EC2 Privada (Backend)         │
│   ┌──────────┐  ┌──────────────┐   │
│   │ Node API │──│   MySQL DB   │   │
│   │  :3000   │  │    :3306     │   │
│   └──────────┘  └──────────────┘   │
└─────────────────────────────────────┘
```

---

## Versiones y Herramientas Requeridas

| Herramienta | Versión |
|---|---|
| Python | 3.8+ |
| pip | 21.0+ |
| Docker | 20.10+ |
| Docker Compose | 2.0+ |

### Dependencias Principales
- **Flask** `2.3.3` - Framework web
- **Flask-CORS** `4.0.0` - Middleware CORS
- **requests** `2.31.0` - Peticiones HTTP
- **python-dotenv** `1.0.0` - Variables de entorno
- **Jinja2** `3.1.2` - Motor de plantillas

---

## Estructura del Proyecto

```
Front_Eval2/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Pipeline CI/CD (GitHub Actions)
├── templates/                  # Plantillas HTML (Jinja2)
│   ├── base.html               # Plantilla base
│   ├── index.html              # Página principal
│   ├── crear_usuario.html      # Formulario crear usuario
│   ├── editar_usuario.html     # Formulario editar usuario
│   ├── 404.html                # Página error 404
│   └── 500.html                # Página error 500
├── app.py                      # Aplicación principal Flask
├── requirements.txt            # Dependencias Python
├── Dockerfile                  # Dockerfile multi-stage
├── docker-compose.yml          # Compose para levantar servicio
├── .dockerignore               # Archivos excluidos del build
├── .env.example                # Ejemplo de variables de entorno
└── README.md                   # Documentación
```

---

## Dockerfile (Multi-Stage Build)

El Dockerfile utiliza **multi-stage build** con las siguientes buenas prácticas:

| Práctica | Implementación |
|---|---|
| **Multi-stage** | Etapa `builder` para instalar dependencias, etapa `production` para ejecutar |
| **Usuario no root** | Se crea `appuser` sin shell ni home, ejecuta con mínimo privilegio |
| **Imagen slim** | Basada en `python:3.11-slim` para reducir superficie de ataque |
| **Cache de capas** | Se copia `requirements.txt` antes del código para optimizar builds |
| **Limpieza** | Se eliminan archivos innecesarios (.env, Dockerfile, etc.) |

### Construir la imagen manualmente:
```bash
docker build -t frontend-flask:latest .
```

### Ejecutar el contenedor:
```bash
docker run -d \
  --name frontend-flask \
  -p 5000:5000 \
  -e BACKEND_URL=http://<IP_BACKEND>:3000 \
  -e SECRET_KEY=clave_secreta_produccion \
  frontend-flask:latest
```

---

## Docker Compose

Levanta el servicio frontend de forma aislada:

```bash
# Levantar el servicio
docker compose up -d

# Ver logs
docker compose logs -f frontend

# Detener
docker compose down
```

---

## Variables de Entorno

| Variable | Descripción | Valor por defecto |
|---|---|---|
| `PORT` | Puerto del servidor Flask | `5000` |
| `DEBUG` | Modo debug | `False` |
| `BACKEND_URL` | URL del backend API | `http://localhost:3000` |
| `SECRET_KEY` | Clave secreta para sesiones Flask | (requerida) |

---

## Pipeline CI/CD (GitHub Actions)

El pipeline se activa con un **push a la rama `deploy`** y ejecuta:

```
Push a rama 'deploy'
       │
       ▼
┌──────────────────┐
│  1. Build Image  │  Construye imagen Docker multi-stage
└────────┬─────────┘
         ▼
┌──────────────────┐
│  2. Push Image   │  Publica en Docker Hub con tags :latest y :sha
└────────┬─────────┘
         ▼
┌──────────────────┐
│  3. Deploy EC2   │  SSH → pull → stop → run nuevo contenedor
└──────────────────┘
```

### Secrets requeridos en GitHub:

| Secret | Descripción |
|---|---|
| `DOCKER_HUB_USERNAME` | Usuario de Docker Hub |
| `DOCKER_HUB_TOKEN` | Token de acceso de Docker Hub |
| `EC2_FRONTEND_HOST` | IP pública de la instancia EC2 del frontend |
| `EC2_USER` | Usuario SSH de EC2 (ej: `ec2-user`, `ubuntu`) |
| `EC2_SSH_KEY` | Clave privada SSH para conexión a EC2 |
| `BACKEND_URL` | URL del backend (ej: `http://<IP_PRIVADA_BACKEND>:3000`) |
| `SECRET_KEY` | Clave secreta para Flask |

### Cómo desplegar:
```bash
# Crear y cambiar a la rama deploy
git checkout -b deploy

# Hacer push para activar el pipeline
git push origin deploy
```

---

## Puertos Requeridos

| Puerto | Servicio | Dirección |
|---|---|---|
| `5000` | Flask (Frontend) | Entrante - acceso desde navegador |
| `3000` | Backend API | Saliente - comunicación con backend |

---

## Funcionalidades

### Páginas Disponibles
- **`/`** - Página principal: lista todos los usuarios con opciones CRUD
- **`/crear`** - Formulario para agregar nuevos usuarios
- **`/editar/<id>`** - Formulario para modificar usuarios existentes
- **Eliminar** - Botón de acción en la lista principal

### Comunicación con Backend
```python
# GET - Obtener usuarios
response = requests.get(f'{BACKEND_URL}/api/usuarios')

# POST - Crear usuario
response = requests.post(f'{BACKEND_URL}/api/usuarios', json=datos)

# PUT - Actualizar usuario
response = requests.put(f'{BACKEND_URL}/api/usuarios/{id}', json=datos)

# DELETE - Eliminar usuario
response = requests.delete(f'{BACKEND_URL}/api/usuarios/{id}')
```

---

## Notas Importantes

- El **backend API** debe estar corriendo antes de iniciar el frontend
- En producción, establecer `DEBUG=False` y usar una `SECRET_KEY` segura
- Solo el **frontend es accesible desde Internet** (EC2 pública)
- La comunicación Front → Back se realiza por la **subred privada de AWS**
