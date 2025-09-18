#!/bin/bash

echo "🧹 Limpieza y setup desde cero..."

cd ~/finanzApp-dev
source venv_finanzapp/bin/activate

# Limpiar proyecto anterior si existe
if [ -d "finanzapp_project" ]; then
    echo "🗑️  Eliminando proyecto anterior..."
    rm -rf finanzapp_project
fi

# Crear proyecto nuevo
echo "🆕 Creando proyecto Django..."
django-admin startproject finanzapp_project

# Entrar al proyecto
cd finanzapp_project

# Crear la aplicación
echo "📱 Creando aplicación core..."
python manage.py startapp core

# Crear directorios
echo "📁 Creando directorios..."
mkdir -p templates/core
mkdir -p static
mkdir -p media

# Crear core/urls.py
echo "🔗 Creando URLs de core..."
cat > core/urls.py << 'EOF'
from django.urls import path
from . import views

app_name = 'core'

urlpatterns = [
    path('', views.home, name='home'),
    path('status/', views.api_status, name='api_status'),
    path('test/', views.api_test, name='api_test'),
]
EOF

# Crear core/views.py
echo "👀 Creando vistas..."
cat > core/views.py << 'EOF'
from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

def home(request):
    context = {
        'title': 'FinanzApp - Sistema Financiero',
        'version': '1.0.0',
        'server_info': 'Servidor: 192.168.0.101:8090'
    }
    return render(request, 'core/home.html', context)

def api_status(request):
    return JsonResponse({
        'status': 'active',
        'service': 'finanzapp',
        'port': 8090,
        'ngrok_url': 'https://finanzapp.ngrok.io',
        'server': '192.168.0.101'
    })

@csrf_exempt
def api_test(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            return JsonResponse({
                'message': 'Datos recibidos correctamente',
                'received_data': data,
                'status': 'success'
            })
        except json.JSONDecodeError:
            return JsonResponse({
                'error': 'JSON inválido',
                'status': 'error'
            }, status=400)
    
    return JsonResponse({
        'message': 'FinanzApp API funcionando correctamente',
        'methods_allowed': ['GET', 'POST'],
        'status': 'success'
    })
EOF

# Actualizar settings.py
echo "⚙️  Configurando settings..."
cat > finanzapp_project/settings.py << 'EOF'
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-your-secret-key-here'

DEBUG = True

ALLOWED_HOSTS = [
    '192.168.0.101',
    'finanzapp.ngrok.io',
    'localhost',
    '127.0.0.1',
    '0.0.0.0'
]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'core',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'finanzapp_project.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'finanzapp_project.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

LANGUAGE_CODE = 'es-es'
TIME_ZONE = 'America/Bogota'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

CSRF_TRUSTED_ORIGINS = [
    'https://finanzapp.ngrok.io',
    'http://192.168.0.101:8090',
]
EOF

# Actualizar urls.py principal
echo "🌐 Configurando URLs principales..."
cat > finanzapp_project/urls.py << 'EOF'
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('core.urls')),
]
EOF

# Crear template
echo "🎨 Creando template..."
cat > templates/core/home.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ title }}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
        }
        .container {
            background: white;
            padding: 2rem;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            text-align: center;
            max-width: 500px;
        }
        .logo { font-size: 3rem; color: #667eea; margin-bottom: 1rem; }
        h1 { color: #333; margin-bottom: 0.5rem; }
        .version { color: #666; margin-bottom: 1.5rem; }
        .status { background: #f8f9fa; padding: 1rem; border-radius: 10px; border-left: 4px solid #28a745; }
        .links { margin-top: 1.5rem; }
        .link { 
            display: inline-block; 
            background: #667eea; 
            color: white; 
            padding: 0.7rem 1.5rem; 
            text-decoration: none; 
            border-radius: 25px; 
            margin: 0.5rem;
        }
        .link:hover { background: #5a67d8; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">💰</div>
        <h1>{{ title }}</h1>
        <div class="version">{{ version }}</div>
        <div class="status">
            <strong>🟢 Servicio Activo</strong><br>
            {{ server_info }}<br>
            Acceso público: https://finanzapp.ngrok.io
        </div>
        <div class="links">
            <a href="/status/" class="link">📊 API Status</a>
            <a href="/test/" class="link">🧪 API Test</a>
            <a href="/admin/" class="link">⚙️ Admin</a>
        </div>
    </div>
</body>
</html>
EOF

# Ejecutar migraciones
echo "🔄 Ejecutando migraciones..."
python manage.py migrate

# Verificar configuración
echo "✅ Verificando configuración..."
python manage.py check

echo "🎉 ¡Setup completado!"
echo "📍 Ejecuta desde: $(pwd)"
echo "🚀 Comando para iniciar: python manage.py runserver 0.0.0.0:8090"
