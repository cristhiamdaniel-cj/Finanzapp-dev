#!/bin/bash
cd /home/desarrollo/finanzApp-dev/finanzapp_project
source /home/desarrollo/finanzApp-dev/venv_finanzapp/bin/activate

# Aplicar migraciones si hay cambios
python manage.py migrate --noinput

# Recopilar archivos estáticos
python manage.py collectstatic --noinput

# Iniciar con gunicorn
exec gunicorn finanzapp_project.wsgi:application \
    --bind 0.0.0.0:8090 \
    --workers 3 \
    --worker-class sync \
    --worker-connections 1000 \
    --max-requests 1000 \
    --max-requests-jitter 100 \
    --timeout 30 \
    --keep-alive 2 \
    --user desarrollo \
    --group desarrollo \
    --log-level info \
    --access-logfile /var/log/finanzapp-access.log \
    --error-logfile /var/log/finanzapp-error.log \
    --pid /tmp/finanzapp.pid
