#!/bin/bash

echo "Solucionando el servicio de archivos estáticos..."

cd ~/finanzApp-dev/finanzapp_project
source ../venv_finanzapp/bin/activate

# Instalar whitenoise para servir archivos estáticos en producción
echo "Instalando whitenoise..."
pip install whitenoise

# Actualizar settings.py para usar whitenoise
echo "Configurando whitenoise en settings.py..."
python -c "
import re

with open('finanzapp_project/settings.py', 'r') as f:
    content = f.read()

# Agregar whitenoise al middleware
middleware_pattern = r'MIDDLEWARE = \[(.*?)\]'
middleware_match = re.search(middleware_pattern, content, re.DOTALL)

if middleware_match:
    middleware_content = middleware_match.group(1)
    if 'whitenoise' not in middleware_content:
        new_middleware = '''MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]'''
        content = re.sub(middleware_pattern, new_middleware, content, flags=re.DOTALL)

# Configurar whitenoise al final del archivo
whitenoise_config = '''

# Configuración de WhiteNoise para archivos estáticos
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
WHITENOISE_USE_FINDERS = True
WHITENOISE_AUTOREFRESH = True
'''

if 'WHITENOISE' not in content:
    content += whitenoise_config

with open('finanzapp_project/settings.py', 'w') as f:
    f.write(content)

print('Settings.py actualizado con WhiteNoise')
"

# Recopilar archivos estáticos nuevamente
echo "Recopilando archivos estáticos..."
python manage.py collectstatic --noinput --clear

# Reiniciar el servicio
echo "Reiniciando servicio..."
sudo systemctl restart finanzapp

# Esperar un momento
sleep 5

echo ""
echo "Configuración completada!"
echo "WhiteNoise configurado para servir archivos estáticos en producción."
echo ""
echo "Prueba acceder a https://finanzapp.ngrok.io/admin/ ahora."
