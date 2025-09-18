#!/bin/bash

echo "🔧 Reparando admin.py con todas las importaciones..."

cd ~/finanzApp-dev/finanzapp_project
source ../venv_finanzapp/bin/activate

# Reescribir completamente el admin.py con todas las importaciones correctas
cat > core/admin.py << 'EOF'
from django.contrib import admin
from .models import (
    Deudor, Deuda, PagoDeuda, CuotaDiferida, 
    Acreedor, MiDeuda, MiPago, RecordatorioDeuda,
    CategoriaFinanciera, SubcategoriaFinanciera, MovimientoFinanciero, 
    PresupuestoCategoria, MetaFinanciera
)

# ===== ADMIN PARA DEUDORES (LO QUE ME DEBEN) =====

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

# ===== ADMIN PARA MIS DEUDAS (LO QUE DEBO) =====

@admin.register(Acreedor)
class AcreedorAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'tipo', 'documento', 'telefono', 'activo', 'fecha_registro']
    list_filter = ['tipo', 'activo', 'fecha_registro']
    search_fields = ['nombre', 'documento', 'contacto_principal']
    ordering = ['nombre']
    fieldsets = (
        ('Información Básica', {
            'fields': ('nombre', 'tipo', 'documento')
        }),
        ('Contacto', {
            'fields': ('telefono', 'email', 'direccion', 'contacto_principal')
        }),
        ('Configuración', {
            'fields': ('activo', 'observaciones')
        }),
    )

@admin.register(MiDeuda)
class MiDeudaAdmin(admin.ModelAdmin):
    list_display = ['acreedor', 'tipo_deuda', 'concepto', 'monto_original', 'saldo_pendiente', 'fecha_vencimiento', 'prioridad', 'estado']
    list_filter = ['tipo_deuda', 'estado', 'prioridad', 'fecha_contrato', 'acreedor']
    search_fields = ['acreedor__nombre', 'concepto', 'numero_cuenta']
    date_hierarchy = 'fecha_contrato'
    ordering = ['-fecha_contrato']
    readonly_fields = ['fecha_creacion', 'fecha_actualizacion']
    
    fieldsets = (
        ('Información del Acreedor', {
            'fields': ('acreedor', 'numero_cuenta', 'tipo_deuda')
        }),
        ('Detalles de la Deuda', {
            'fields': ('concepto', 'monto_original', 'saldo_pendiente', 'tasa_interes')
        }),
        ('Fechas y Plazos', {
            'fields': ('fecha_contrato', 'fecha_vencimiento', 'cuota_mensual', 'plazo_meses')
        }),
        ('Estado y Prioridad', {
            'fields': ('estado', 'prioridad', 'observaciones')
        }),
        ('Información del Sistema', {
            'fields': ('fecha_creacion', 'fecha_actualizacion'),
            'classes': ('collapse',)
        }),
    )

@admin.register(MiPago)
class MiPagoAdmin(admin.ModelAdmin):
    list_display = ['mi_deuda', 'monto_pago', 'monto_capital', 'monto_interes', 'fecha_pago', 'metodo_pago']
    list_filter = ['metodo_pago', 'fecha_pago', 'mi_deuda__acreedor']
    search_fields = ['mi_deuda__acreedor__nombre', 'numero_transaccion', 'comprobante']
    date_hierarchy = 'fecha_pago'
    ordering = ['-fecha_pago']
    
    fieldsets = (
        ('Información del Pago', {
            'fields': ('mi_deuda', 'monto_pago', 'fecha_pago')
        }),
        ('Distribución del Pago', {
            'fields': ('monto_capital', 'monto_interes')
        }),
        ('Método y Comprobantes', {
            'fields': ('metodo_pago', 'numero_transaccion', 'comprobante')
        }),
        ('Observaciones', {
            'fields': ('observaciones',)
        }),
    )

@admin.register(RecordatorioDeuda)
class RecordatorioDeudaAdmin(admin.ModelAdmin):
    list_display = ['mi_deuda', 'fecha_recordatorio', 'dias_anticipacion', 'activo', 'enviado']
    list_filter = ['activo', 'enviado', 'fecha_recordatorio']
    search_fields = ['mi_deuda__acreedor__nombre', 'mensaje']
    ordering = ['fecha_recordatorio']

# ===== ADMIN PARA INGRESOS Y EGRESOS =====

@admin.register(CategoriaFinanciera)
class CategoriaFinancieraAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'tipo', 'naturaleza', 'activo', 'fecha_creacion']
    list_filter = ['tipo', 'naturaleza', 'activo']
    search_fields = ['nombre', 'descripcion']
    ordering = ['tipo', 'naturaleza', 'nombre']
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('nombre', 'tipo', 'naturaleza')
        }),
        ('Detalles', {
            'fields': ('descripcion', 'activo')
        }),
    )

@admin.register(SubcategoriaFinanciera)
class SubcategoriaFinancieraAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'categoria', 'activo', 'fecha_creacion']
    list_filter = ['categoria__tipo', 'categoria__naturaleza', 'activo']
    search_fields = ['nombre', 'categoria__nombre']
    ordering = ['categoria__tipo', 'categoria__nombre', 'nombre']

@admin.register(MovimientoFinanciero)
class MovimientoFinancieroAdmin(admin.ModelAdmin):
    list_display = ['descripcion', 'tipo', 'categoria', 'subcategoria', 'monto', 'fecha', 'metodo_pago']
    list_filter = ['tipo', 'categoria', 'metodo_pago', 'es_recurrente', 'fecha']
    search_fields = ['descripcion', 'categoria__nombre', 'subcategoria__nombre', 'referencia']
    date_hierarchy = 'fecha'
    ordering = ['-fecha', '-fecha_creacion']
    readonly_fields = ['fecha_creacion', 'fecha_actualizacion']
    
    fieldsets = (
        ('Información Principal', {
            'fields': ('tipo', 'categoria', 'subcategoria', 'descripcion', 'monto', 'fecha')
        }),
        ('Recurrencia', {
            'fields': ('es_recurrente', 'frecuencia', 'fecha_fin_recurrencia'),
            'classes': ('collapse',)
        }),
        ('Método de Pago', {
            'fields': ('metodo_pago', 'referencia', 'comprobante')
        }),
        ('Información Adicional', {
            'fields': ('notas',)
        }),
        ('Auditoría', {
            'fields': ('fecha_creacion', 'fecha_actualizacion'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('categoria', 'subcategoria')

@admin.register(PresupuestoCategoria)
class PresupuestoCategoriaAdmin(admin.ModelAdmin):
    list_display = ['categoria', 'año', 'mes', 'monto_presupuestado', 'monto_ejecutado', 'porcentaje_ejecucion']
    list_filter = ['año', 'mes', 'categoria__tipo', 'categoria']
    search_fields = ['categoria__nombre']
    ordering = ['-año', '-mes', 'categoria__nombre']
    
    def monto_ejecutado(self, obj):
        return f"${obj.monto_ejecutado:,.2f}"
    monto_ejecutado.short_description = "Monto Ejecutado"
    
    def porcentaje_ejecucion(self, obj):
        return f"{obj.porcentaje_ejecucion:.1f}%"
    porcentaje_ejecucion.short_description = "% Ejecución"

@admin.register(MetaFinanciera)
class MetaFinancieraAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'tipo', 'monto_objetivo', 'monto_actual', 'porcentaje_completado', 'fecha_objetivo', 'estado']
    list_filter = ['tipo', 'estado', 'fecha_objetivo']
    search_fields = ['nombre', 'descripcion']
    ordering = ['-fecha_objetivo']
    readonly_fields = ['porcentaje_completado', 'monto_faltante', 'dias_restantes', 'fecha_creacion', 'fecha_actualizacion']
    
    fieldsets = (
        ('Información Principal', {
            'fields': ('nombre', 'descripcion', 'tipo')
        }),
        ('Montos', {
            'fields': ('monto_objetivo', 'monto_actual', 'porcentaje_completado', 'monto_faltante')
        }),
        ('Fechas', {
            'fields': ('fecha_inicio', 'fecha_objetivo', 'dias_restantes')
        }),
        ('Estado', {
            'fields': ('estado', 'notas')
        }),
        ('Auditoría', {
            'fields': ('fecha_creacion', 'fecha_actualizacion'),
            'classes': ('collapse',)
        }),
    )
    
    def porcentaje_completado(self, obj):
        return f"{obj.porcentaje_completado:.1f}%"
    porcentaje_completado.short_description = "% Completado"
EOF

echo "✅ Admin.py reparado con todas las importaciones"

# Crear migraciones
echo "🔄 Creando migraciones..."
python manage.py makemigrations core

echo "📦 Aplicando migraciones..."
python manage.py migrate

echo "✅ Verificando configuración..."
python manage.py check

# Reiniciar servicio
echo "🚀 Reiniciando servicio..."
sudo systemctl restart finanzapp

echo ""
echo "🎉 ¡Todo reparado y funcionando!"
echo "🌐 Ve a https://finanzapp.ngrok.io/admin/ para ver todas las nuevas secciones."
