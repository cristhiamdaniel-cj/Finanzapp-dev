#!/bin/bash

# Script de despliegue completo para FinanzApp
# Ejecutar desde ~/finanzApp-dev

echo "🚀 Iniciando despliegue de FinanzApp..."

# 1. Verificar que estamos en el directorio correcto
if [ ! -d "venv_finanzapp" ]; then
    echo "⚠️  No se encontró el entorno virtual. Creando..."
    python3 -m venv venv_finanzapp
fi

# 2. Activar entorno virtual e instalar dependencias
source venv_finanzapp/bin/activate
pip install django gunicorn

# 3. Si no existe el proyecto, crearlo
if [ ! -d "finanzapp_project" ]; then
    echo "📁 Creando proyecto Django..."
    django-admin startproject finanzapp_project .
    cd finanzapp_project
    python manage.py startapp core
else
    cd finanzapp_project
fi

# 4. Crear estructura de directorios
mkdir -p templates/core
mkdir -p static
mkdir -p media

# 5. Crear el template HTML
cat > templates/core/home.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ title }}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Arial', sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; display: flex; align-items: center; justify-content: center;
        }
        .container { 
            background: rgba(255, 255, 255, 0.95); padding: 2rem; border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1); text-align: center; max-width: 500px; width: 90%;
        }
        .logo { font-size: 3rem; color: #667eea; margin-bottom: 1rem; }
        h1 { color: #333; margin-bottom: 0.5rem; font-size: 2rem; }
        .version { color: #666; font-size: 0.9rem; margin-bottom: 1.5rem; }
        .status-card { 
            background: #f8f9fa; border-radius: 10px; padding: 1.5rem; margin: 1rem 0; 
            border-left: 4px solid #28a745;
        }
        .status-title { color: #28a745; font-weight: bold; margin-bottom: 0.5rem; }
        .server-info { color: #666; font-size: 0.9rem; }
        .api-links { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; margin-top: 1.5rem; }
        .api-link { 
            background: #667eea; color: white; padding: 0.7rem 1.5rem; text-decoration: none; 
            border-radius: 25px; transition: all 0.3s ease; font-weight: 500;
        }
        .api-link:hover { background: #5a67d8; transform: translateY(-2px); box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3); }
        .footer { margin-top: 2rem; color: #999; font-size: 0.8rem; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">💰</div>
        <h1>{{ title }}</h1>
        <div class="version">{{ version }}</div>
        <div class="status-card">
            <div class="status-title">🟢 Servicio Activo</div>
            <div class="server-info">{{ server_info }}</div>
            <div class="server-info">Acceso público: https://finanzapp.ngrok.io</div>
        </div>
        <div class="api-links">
            <a href="/status/" class="api-link">📊 API Status</a>
            <a href="/test/" class="api-link">🧪 API Test</a>
            <a href="/admin/" class="api-link">⚙️ Admin</a>
        </div>
        <div class="footer">Sistema desplegado en servidor Ubuntu 24.04<br>Puerto: 8090 | Túnel: ngrok</div>
    </div>
</body>
</html>
EOF

# 6. Ejecutar migraciones
python manage.py makemigrations
python manage.py migrate

# 7. Recopilar archivos estáticos
python manage.py collectstatic --noinput

# 8. Probar que funciona
echo "🧪 Probando configuración..."
python manage.py check

# 9. Iniciar el servidor con Gunicorn
echo "🔥 Iniciando servidor en puerto 8090..."
echo "Acceso local: http://192.168.0.101:8090"
echo "Acceso público: https://finanzapp.ngrok.io"

# Ejecutar servidor
gunicorn --workers 3 --bind 0.0.0.0:8090 --reload finanzapp_project.wsgi:application