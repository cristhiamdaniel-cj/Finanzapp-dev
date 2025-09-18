#!/bin/bash

echo "🔧 Reparando configuración de archivos estáticos..."

cd ~/finanzApp-dev/finanzapp_project
source ../venv_finanzapp/bin/activate

# Verificar la configuración actual
echo "📋 Configuración actual de archivos estáticos:"
python -c "
from django.conf import settings
import os
print(f'STATIC_URL: {settings.STATIC_URL}')
print(f'STATIC_ROOT: {settings.STATIC_ROOT}')
print(f'BASE_DIR: {settings.BASE_DIR}')
print(f'Directorio actual: {os.getcwd()}')
"

# Crear directorio staticfiles si no existe
echo "📁 Creando directorios necesarios..."
mkdir -p /home/desarrollo/finanzApp-dev/finanzapp_project/staticfiles
mkdir -p /home/desarrollo/finanzApp-dev/finanzapp_project/static

# Recopilar archivos estáticos
echo "📦 Recopilando archivos estáticos..."
python manage.py collectstatic --noinput --verbosity=2

# Verificar que se crearon los archivos
echo "✅ Verificando archivos estáticos..."
ls -la staticfiles/admin/css/ | head -10
echo "..."

# Actualizar configuración de Django para servir archivos estáticos
echo "⚙️ Actualizando configuración..."

# Agregar configuración para servir archivos estáticos en producción
cat >> finanzapp_project/urls.py << 'EOF'

# Servir archivos estáticos en producción
from django.conf import settings
from django.conf.urls.static import static

if not settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
EOF

# Actualizar settings.py para mejor configuración de estáticos
echo "📝 Actualizando settings.py..."
python -c "
import re

with open('finanzapp_project/settings.py', 'r') as f:
    content = f.read()

# Actualizar configuración de archivos estáticos
static_config = '''
# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Configuración adicional para archivos estáticos
STATICFILES_FINDERS = [
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
]
'''

# Buscar y reemplazar la configuración existente
pattern = r'# Static files.*?DEFAULT_AUTO_FIELD = [^\n]*'
if re.search(pattern, content, re.DOTALL):
    content = re.sub(pattern, static_config + '\n\nDEFAULT_AUTO_FIELD = \"django.db.models.BigAutoField\"', content, flags=re.DOTALL)
else:
    content += '\n' + static_config

with open('finanzapp_project/settings.py', 'w') as f:
    f.write(content)
"

echo "🔄 Recopilando archivos estáticos nuevamente..."
python manage.py collectstatic --noinput --clear

# Reiniciar el servicio
echo "🚀 Reiniciando servicio FinanzApp..."
sudo systemctl restart finanzapp

# Esperar un momento
sleep 5

# Verificar estado
echo "📊 Estado del servicio:"
sudo systemctl status finanzapp --no-pager | head -10

echo ""
echo "🎉 ¡Archivos estáticos configurados!"
echo ""
echo "🔍 Verificaciones realizadas:"
echo "   ✅ Archivos estáticos recopilados"
echo "   ✅ Configuración de URLs actualizada"
echo "   ✅ Settings.py optimizado"
echo "   ✅ Servicio reiniciado"
echo ""
echo "🌐 Prueba acceder nuevamente a:"
echo "   https://finanzapp.ngrok.io/admin/"
echo ""
echo "💡 Si persisten problemas, ejecuta:"
echo "   sudo journalctl -u finanzapp -f"
