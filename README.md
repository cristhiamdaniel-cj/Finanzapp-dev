# FinanzApp - Aplicación de Gestión Financiera

## Descripción

FinanzApp es una aplicación completa de gestión financiera que permite a los usuarios administrar sus ingresos, egresos y deudas de manera eficiente. La aplicación está construida con una arquitectura moderna utilizando Django como backend y Node.js/Next.js como frontend.

## Arquitectura del Sistema

### Backend - Django API
- **Framework**: Django + Django REST Framework
- **Servidor**: Gunicorn
- **Puerto**: 8090
- **URL Local**: `http://localhost:8090`
- **URL Producción**: `https://finanzapp.ngrok.io`
- **Servicio systemd**: `finanzapp.service`

### Frontend Node.js
- **Framework**: Next.js (Node.js)  
- **Puerto**: 8029
- **URL Local**: `http://192.168.0.101:8029`
- **URL Producción**: `https://finanzapp-dev.ngrok.io`
- **Servicio systemd**: `finanzapp-frontend.service`
- **Servidor**: Custom Node.js Server

## URLs de Acceso

### Desarrollo Local
- **Backend API**: `http://192.168.0.101:8090`
- **Frontend**: `http://192.168.0.101:8029`

### Producción (Ngrok Tunnels)
- **Frontend (Aplicación Principal)**: `https://finanzapp-dev.ngrok.io`
- **Backend API**: `https://finanzapp.ngrok.io`
- **API Endpoints**: `https://finanzapp.ngrok.io/api/`

## Gestión de Servicios

### Backend Django (systemd)

El backend se ejecuta como un servicio systemd para garantizar disponibilidad 24/7:

```bash
# Ver estado del servicio
sudo systemctl status finanzapp

# Iniciar servicio
sudo systemctl start finanzapp

# Detener servicio
sudo systemctl stop finanzapp

# Reiniciar servicio
sudo systemctl restart finanzapp

# Recargar configuración
sudo systemctl reload finanzapp
```

### Frontend Next.js (systemd)

El frontend también se ejecuta como servicio systemd:

```bash
# Ver estado del servicio
sudo systemctl status finanzapp-frontend

# Iniciar servicio
sudo systemctl start finanzapp-frontend

# Detener servicio
sudo systemctl stop finanzapp-frontend

# Reiniciar servicio
sudo systemctl restart finanzapp-frontend

# Recargar configuración
sudo systemctl reload finanzapp-frontend
```

### Gestión de Ambos Servicios

```bash
# Iniciar ambos servicios
sudo systemctl start finanzapp finanzapp-frontend

# Detener ambos servicios
sudo systemctl stop finanzapp finanzapp-frontend

# Reiniciar ambos servicios
sudo systemctl restart finanzapp finanzapp-frontend

# Ver estado de ambos
sudo systemctl status finanzapp finanzapp-frontend
```

## Verificar Túneles Ngrok Activos

```bash
# Ver todos los túneles ngrok activos
curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | "\(.name) → \(.public_url) (addr: \(.config.addr))"'

# Verificar específicamente FinanzApp
curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.name | contains("finanzapp")) | "\(.name) → \(.public_url)"'
```

## Logs y Monitoreo

### Logs del Backend

```bash
# Logs en tiempo real del servicio backend
sudo journalctl -u finanzapp -f

# Logs de hoy del backend
sudo journalctl -u finanzapp --since today

# Logs de acceso
tail -f /var/log/finanzapp-access.log

# Logs de errores
tail -f /var/log/finanzapp-error.log
```

### Logs del Frontend

```bash
# Logs en tiempo real del servicio frontend
sudo journalctl -u finanzapp-frontend -f

# Logs de hoy del frontend
sudo journalctl -u finanzapp-frontend --since today

# Logs específicos del frontend
tail -f /var/log/finanzapp-frontend.log
```

### Logs de Ambos Servicios

```bash
# Ver logs de ambos servicios en tiempo real
sudo journalctl -u finanzapp -u finanzapp-frontend -f
```

### Verificar Puertos Activos

```bash
# Verificar que ambos servicios estén corriendo
ss -tulpn | grep -E ":(8029|8090)"

# Verificar solo backend
ss -tulpn | grep :8090

# Verificar solo frontend  
ss -tulpn | grep :8029
```

## Configuración del Entorno

### Backend
- **Directorio**: `/home/desarrollo/finanzApp-dev/finanzapp_project`
- **Entorno Virtual**: `/home/desarrollo/finanzApp-dev/venv_finanzapp`
- **Base de Datos**: SQLite3 (desarrollo)

### Frontend
- **Directorio**: `/home/desarrollo/finanzApp-dev/finanzapp-frontend`
- **Node.js**: Versión compatible con Next.js

## Funcionalidades Principales

### Módulos Disponibles
- ✅ **Dashboard Principal** - Resumen financiero general
- ✅ **Gestión de Deudores** - Control de personas que te deben dinero
- ✅ **Mis Deudas** - Seguimiento de tus propias deudas
- ✅ **Movimientos Financieros** - Registro de ingresos y egresos
- ✅ **Categorías** - Organización de transacciones por categorías
- ✅ **API RESTful** - Backend robusto con Django REST Framework
- ✅ **Interfaz Moderna** - Frontend responsive con Node.js/Express
- ✅ **Servicios 24/7** - Disponibilidad continua con systemd

### URLs de Acceso por Módulo
- **Dashboard**: `https://finanzapp-dev.ngrok.io/`
- **Deudores**: `https://finanzapp-dev.ngrok.io/deudores`
- **Mis Deudas**: `https://finanzapp-dev.ngrok.io/mis-deudas`
- **Movimientos**: `https://finanzapp-dev.ngrok.io/movimientos`
- **Categorías**: `https://finanzapp-dev.ngrok.io/categorias`
- **API Backend**: `https://finanzapp.ngrok.io/api/`

## Desarrollo

### Prerequisitos
- Python 3.8+
- Node.js 16+
- Git

### Configuración Local

1. **Clonar el repositorio**
```bash
git clone https://github.com/cristhiamdaniel-cj/Finanzapp-dev.git
cd Finanzapp-dev
```

2. **Configurar Backend**
```bash
# Crear entorno virtual
python -m venv venv_finanzapp
source venv_finanzapp/bin/activate

# Instalar dependencias
cd finanzapp_project
pip install -r requirements.txt

# Ejecutar migraciones
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser

# Ejecutar servidor de desarrollo
python manage.py runserver 0.0.0.0:8090
```

3. **Configurar Frontend**
```bash
# En otra terminal
cd finanzapp-frontend

# Instalar dependencias
npm install

# Ejecutar en desarrollo
npm run dev
```

## Estructura del Proyecto

```
finanzApp-dev/
├── core/                     # Aplicaciones Django principales
├── finanzapp_project/        # Configuración del proyecto Django  
├── finanzapp-frontend/       # Aplicación Next.js
├── manage.py                 # Comando de Django
├── README.md                 # Este archivo
└── start_finanzapp.sh        # Script de inicio del servicio
```

## Contacto

Para más información sobre el desarrollo y configuración del proyecto, consultar la documentación del código o contactar al equipo de desarrollo.
