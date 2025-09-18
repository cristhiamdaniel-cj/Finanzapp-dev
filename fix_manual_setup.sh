#!/bin/bash

echo "🔧 Reparando configuración manualmente..."

cd ~/finanzApp-dev/finanzapp_project
source ../venv_finanzapp/bin/activate

# 1. Primero, crear los modelos correctamente
echo "📝 Creando models.py..."
cat > core/models.py << 'EOF'
from django.db import models
from django.utils import timezone
from decimal import Decimal

class Deudor(models.Model):
    nombre = models.CharField(max_length=200, verbose_name="Nombre completo")
    documento = models.CharField(max_length=50, unique=True, verbose_name="Documento de identidad")
    telefono = models.CharField(max_length=20, blank=True, verbose_name="Teléfono")
    email = models.EmailField(blank=True, verbose_name="Correo electrónico")
    direccion = models.TextField(blank=True, verbose_name="Dirección")
    fecha_registro = models.DateTimeField(auto_now_add=True, verbose_name="Fecha de registro")
    activo = models.BooleanField(default=True, verbose_name="Activo")
    
    class Meta:
        verbose_name = "Deudor"
        verbose_name_plural = "Deudores"
        ordering = ['nombre']
    
    def __str__(self):
        return f"{self.nombre} - {self.documento}"
    
    @property
    def total_deuda(self):
        return self.deudas.filter(estado='PENDIENTE').aggregate(
            total=models.Sum('monto_pendiente')
        )['total'] or Decimal('0.00')
    
    @property
    def deudas_vencidas(self):
        return self.deudas.filter(
            estado='PENDIENTE',
            fecha_vencimiento__lt=timezone.now().date()
        )

class Deuda(models.Model):
    ESTADO_CHOICES = [
        ('PENDIENTE', 'Pendiente'),
        ('PAGADA', 'Pagada'),
        ('VENCIDA', 'Vencida'),
        ('PARCIAL', 'Pago Parcial'),
    ]
    
    TIPO_CHOICES = [
        ('UNICA', 'Pago Único'),
        ('DIFERIDA', 'Pago Diferido'),
    ]
    
    deudor = models.ForeignKey(Deudor, on_delete=models.CASCADE, related_name='deudas')
    concepto = models.CharField(max_length=300, verbose_name="Concepto de la deuda")
    monto_original = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Monto original")
    monto_pendiente = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Monto pendiente")
    fecha_prestamo = models.DateField(verbose_name="Fecha del préstamo")
    fecha_vencimiento = models.DateField(verbose_name="Fecha de vencimiento")
    tipo_pago = models.CharField(max_length=10, choices=TIPO_CHOICES, default='UNICA', verbose_name="Tipo de pago")
    meses_diferido = models.PositiveIntegerField(null=True, blank=True, verbose_name="Meses diferidos")
    tasa_interes = models.DecimalField(max_digits=5, decimal_places=2, default=0, verbose_name="Tasa de interés (%)")
    estado = models.CharField(max_length=10, choices=ESTADO_CHOICES, default='PENDIENTE')
    observaciones = models.TextField(blank=True, verbose_name="Observaciones")
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Deuda"
        verbose_name_plural = "Deudas"
        ordering = ['-fecha_prestamo']
    
    def __str__(self):
        return f"{self.deudor.nombre} - ${self.monto_pendiente:,.2f}"
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.monto_pendiente = self.monto_original
        
        if self.fecha_vencimiento < timezone.now().date() and self.estado == 'PENDIENTE':
            self.estado = 'VENCIDA'
        
        super().save(*args, **kwargs)
    
    @property
    def dias_vencimiento(self):
        delta = self.fecha_vencimiento - timezone.now().date()
        return delta.days

class PagoDeuda(models.Model):
    deuda = models.ForeignKey(Deuda, on_delete=models.CASCADE, related_name='pagos')
    monto_pago = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Monto del pago")
    fecha_pago = models.DateField(verbose_name="Fecha del pago")
    metodo_pago = models.CharField(max_length=50, verbose_name="Método de pago", 
                                   choices=[
                                       ('EFECTIVO', 'Efectivo'),
                                       ('TRANSFERENCIA', 'Transferencia'),
                                       ('CHEQUE', 'Cheque'),
                                       ('OTRO', 'Otro'),
                                   ])
    comprobante = models.CharField(max_length=100, blank=True, verbose_name="Número de comprobante")
    observaciones = models.TextField(blank=True, verbose_name="Observaciones del pago")
    fecha_registro = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Pago de Deuda"
        verbose_name_plural = "Pagos de Deudas"
        ordering = ['-fecha_pago']
    
    def __str__(self):
        return f"Pago ${self.monto_pago:,.2f} - {self.deuda.deudor.nombre}"

class CuotaDiferida(models.Model):
    deuda = models.ForeignKey(Deuda, on_delete=models.CASCADE, related_name='cuotas')
    numero_cuota = models.PositiveIntegerField(verbose_name="Número de cuota")
    monto_cuota = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Monto de la cuota")
    fecha_vencimiento = models.DateField(verbose_name="Fecha de vencimiento")
    pagada = models.BooleanField(default=False, verbose_name="Pagada")
    fecha_pago = models.DateField(null=True, blank=True, verbose_name="Fecha de pago")
    
    class Meta:
        verbose_name = "Cuota Diferida"
        verbose_name_plural = "Cuotas Diferidas"
        ordering = ['numero_cuota']
        unique_together = ['deuda', 'numero_cuota']
    
    def __str__(self):
        return f"Cuota {self.numero_cuota} - {self.deuda.deudor.nombre}"
EOF

# 2. Crear admin.py
echo "⚙️ Creando admin.py..."
cat > core/admin.py << 'EOF'
from django.contrib import admin
from .models import Deudor, Deuda, PagoDeuda, CuotaDiferida

@admin.register(Deudor)
class DeudorAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'documento', 'telefono', 'fecha_registro', 'activo']
    list_filter = ['activo', 'fecha_registro']
    search_fields = ['nombre', 'documento', 'telefono']
    ordering = ['nombre']

@admin.register(Deuda)
class DeudaAdmin(admin.ModelAdmin):
    list_display = ['deudor', 'concepto', 'monto_original', 'monto_pendiente', 'fecha_vencimiento', 'estado']
    list_filter = ['estado', 'tipo_pago', 'fecha_prestamo']
    search_fields = ['deudor__nombre', 'concepto']
    date_hierarchy = 'fecha_prestamo'

@admin.register(PagoDeuda)
class PagoDeudaAdmin(admin.ModelAdmin):
    list_display = ['deuda', 'monto_pago', 'fecha_pago', 'metodo_pago']
    list_filter = ['metodo_pago', 'fecha_pago']
    search_fields = ['deuda__deudor__nombre', 'comprobante']

@admin.register(CuotaDiferida)
class CuotaDiferidaAdmin(admin.ModelAdmin):
    list_display = ['deuda', 'numero_cuota', 'monto_cuota', 'fecha_vencimiento', 'pagada']
    list_filter = ['pagada', 'fecha_vencimiento']
    search_fields = ['deuda__deudor__nombre']
EOF

# 3. Crear las migraciones primero
echo "🔄 Creando migraciones para los modelos..."
python manage.py makemigrations core

# 4. Aplicar migraciones
echo "📦 Aplicando migraciones..."
python manage.py migrate

# 5. Ahora actualizar views.py con una versión básica primero
echo "👀 Creando views básicas..."
cat > core/views.py << 'EOF'
from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

def home(request):
    context = {
        'title': 'FinanzApp - Sistema Financiero',
        'version': '1.0.0',
        'server_info': 'Servidor: 192.168.0.101:8090',
        'total_deudores': 0,
        'total_deuda': 0,
        'deudas_vencidas': 0,
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

# Vistas básicas para deudores (temporalmente simples)
def lista_deudores(request):
    return render(request, 'core/mensaje.html', {
        'titulo': 'Lista de Deudores',
        'mensaje': 'Funcionalidad en construcción'
    })

def dashboard_deudas(request):
    return render(request, 'core/mensaje.html', {
        'titulo': 'Dashboard',
        'mensaje': 'Dashboard en construcción'
    })

def crear_deudor(request):
    return render(request, 'core/mensaje.html', {
        'titulo': 'Crear Deudor',
        'mensaje': 'Formulario en construcción'
    })

def crear_deuda(request, deudor_id=None):
    return render(request, 'core/mensaje.html', {
        'titulo': 'Crear Deuda',
        'mensaje': 'Formulario en construcción'
    })

def detalle_deudor(request, deudor_id):
    return render(request, 'core/mensaje.html', {
        'titulo': 'Detalle Deudor',
        'mensaje': 'Vista en construcción'
    })

def registrar_pago(request, deuda_id):
    return render(request, 'core/mensaje.html', {
        'titulo': 'Registrar Pago',
        'mensaje': 'Formulario en construcción'
    })
EOF

# 6. Crear template temporal para mensajes
echo "📄 Creando template temporal..."
mkdir -p templates/core
cat > templates/core/mensaje.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>{{ titulo }} - FinanzApp</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 2rem; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 2rem; border-radius: 10px; }
        .btn { background: #667eea; color: white; padding: 0.7rem 1.5rem; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>{{ titulo }}</h1>
        <p>{{ mensaje }}</p>
        <a href="{% url 'core:home' %}" class="btn">🏠 Volver al inicio</a>
    </div>
</body>
</html>
EOF

# 7. Actualizar URLs para que funcionen
echo "🔗 Actualizando URLs..."
cat > core/urls.py << 'EOF'
from django.urls import path
from . import views

app_name = 'core'

urlpatterns = [
    path('', views.home, name='home'),
    path('status/', views.api_status, name='api_status'),
    path('test/', views.api_test, name='api_test'),
    
    # URLs básicas para deudores
    path('dashboard/', views.dashboard_deudas, name='dashboard_deudas'),
    path('deudores/', views.lista_deudores, name='lista_deudores'),
    path('deudores/nuevo/', views.crear_deudor, name='crear_deudor'),
    path('deudores/<int:deudor_id>/', views.detalle_deudor, name='detalle_deudor'),
    path('deudas/nueva/', views.crear_deuda, name='crear_deuda'),
    path('deudas/nueva/<int:deudor_id>/', views.crear_deuda, name='crear_deuda_deudor'),
    path('deudas/<int:deuda_id>/pago/', views.registrar_pago, name='registrar_pago'),
]
EOF

# 8. Verificar que todo funciona
echo "✅ Verificando configuración..."
python manage.py check

echo ""
echo "🎉 ¡Configuración básica reparada!"
echo ""
echo "🚀 Ahora puedes iniciar el servidor:"
echo "   python manage.py runserver 0.0.0.0:8090"
echo ""
echo "📝 Los modelos están creados, pero las vistas están en modo básico."
echo "📧 Una vez que confirmes que funciona, podemos agregar la funcionalidad completa."