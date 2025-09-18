#!/bin/bash

echo "🚀 Configurando FinanzApp como servicio systemd 24/7..."

# Detener el servidor de desarrollo si está corriendo
echo "⏹️ Deteniendo servidor de desarrollo..."
pkill -f "python manage.py runserver" 2>/dev/null || true

# Activar entorno virtual
cd ~/finanzApp-dev
source venv_finanzapp/bin/activate

# Instalar gunicorn si no está instalado
echo "📦 Verificando gunicorn..."
pip install gunicorn

# Crear script de inicio
echo "📝 Creando script de inicio..."
cat > start_finanzapp.sh << 'EOF'
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
EOF

chmod +x start_finanzapp.sh

# Crear archivo de servicio systemd
echo "⚙️ Creando servicio systemd..."
sudo tee /etc/systemd/system/finanzapp.service << EOF
[Unit]
Description=FinanzApp Django Application
Documentation=https://finanzapp.ngrok.io
After=network.target
Wants=network.target

[Service]
Type=exec
User=desarrollo
Group=desarrollo
WorkingDirectory=/home/desarrollo/finanzApp-dev
ExecStart=/home/desarrollo/finanzApp-dev/start_finanzapp.sh
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Variables de entorno
Environment=PYTHONPATH=/home/desarrollo/finanzApp-dev/finanzapp_project
Environment=DJANGO_SETTINGS_MODULE=finanzapp_project.settings

[Install]
WantedBy=multi-user.target
EOF

# Crear directorios de logs
echo "📁 Configurando logs..."
sudo touch /var/log/finanzapp-access.log
sudo touch /var/log/finanzapp-error.log
sudo chown desarrollo:desarrollo /var/log/finanzapp-*.log

# Recargar systemd
echo "🔄 Recargando systemd..."
sudo systemctl daemon-reload

# Habilitar el servicio para inicio automático
echo "✅ Habilitando servicio para inicio automático..."
sudo systemctl enable finanzapp.service

# Iniciar el servicio
echo "🚀 Iniciando servicio FinanzApp..."
sudo systemctl start finanzapp.service

# Esperar un momento para que inicie
sleep 3

# Verificar estado
echo "📊 Estado del servicio:"
sudo systemctl status finanzapp.service --no-pager

echo ""
echo "🎉 ¡FinanzApp configurado como servicio systemd!"
echo ""
echo "📋 Comandos útiles para gestionar el servicio:"
echo ""
echo "   sudo systemctl status finanzapp      # Ver estado del servicio"
echo "   sudo systemctl start finanzapp       # Iniciar servicio"
echo "   sudo systemctl stop finanzapp        # Detener servicio"
echo "   sudo systemctl restart finanzapp     # Reiniciar servicio"
echo "   sudo systemctl reload finanzapp      # Recargar configuración"
echo ""
echo "📋 Comandos para logs:"
echo ""
echo "   sudo journalctl -u finanzapp -f      # Ver logs en tiempo real"
echo "   sudo journalctl -u finanzapp --since today  # Logs de hoy"
echo "   tail -f /var/log/finanzapp-access.log       # Logs de acceso"
echo "   tail -f /var/log/finanzapp-error.log        # Logs de errores"
echo ""
echo "🌐 Tu aplicación ahora está disponible 24/7 en:"
echo "   https://finanzapp.ngrok.io"
echo "   http://192.168.0.101:8090"
echo ""
echo "🔄 El servicio se reiniciará automáticamente:"
echo "   - Al reiniciar el servidor"
echo "   - Si el proceso falla"
echo "   - Cada 10 segundos en caso de error"