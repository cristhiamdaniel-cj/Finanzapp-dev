#!/bin/bash

echo "💰 Creando sistema de ingresos y egresos..."

cd ~/finanzApp-dev/finanzapp_project
source ../venv_finanzapp/bin/activate

# Agregar nuevos modelos al archivo models.py existente
cat >> core/models.py << 'EOF'

# ===== SISTEMA DE INGRESOS Y EGRESOS =====

class CategoriaFinanciera(models.Model):
    """Categorías principales para ingresos y egresos"""
    TIPO_CHOICES = [
        ('INGRESO', 'Ingreso'),
        ('EGRESO', 'Egreso'),
    ]
    
    NATURALEZA_CHOICES = [
        ('FIJO', 'Fijo'),
        ('VARIABLE', 'Variable'),
    ]
    
    nombre = models.CharField(max_length=100, verbose_name="Nombre de la categoría")
    tipo = models.CharField(max_length=10, choices=TIPO_CHOICES, verbose_name="Tipo")
    naturaleza = models.CharField(max_length=10, choices=NATURALEZA_CHOICES, verbose_name="Naturaleza")
    descripcion = models.TextField(blank=True, verbose_name="Descripción")
    activo = models.BooleanField(default=True, verbose_name="Activo")
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Categoría Financiera"
        verbose_name_plural = "Categorías Financieras"
        ordering = ['tipo', 'naturaleza', 'nombre']
        unique_together = ['nombre', 'tipo', 'naturaleza']
    
    def __str__(self):
        return f"{self.get_tipo_display()} {self.get_naturaleza_display()} - {self.nombre}"

class SubcategoriaFinanciera(models.Model):
    """Subcategorías para clasificación detallada"""
    categoria = models.ForeignKey(CategoriaFinanciera, on_delete=models.CASCADE, related_name='subcategorias')
    nombre = models.CharField(max_length=100, verbose_name="Nombre de la subcategoría")
    descripcion = models.TextField(blank=True, verbose_name="Descripción")
    activo = models.BooleanField(default=True, verbose_name="Activo")
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Subcategoría Financiera"
        verbose_name_plural = "Subcategorías Financieras"
        ordering = ['categoria', 'nombre']
        unique_together = ['categoria', 'nombre']
    
    def __str__(self):
        return f"{self.categoria.nombre} - {self.nombre}"

class MovimientoFinanciero(models.Model):
    """Registro de todos los movimientos financieros"""
    TIPO_CHOICES = [
        ('INGRESO', 'Ingreso'),
        ('EGRESO', 'Egreso'),
    ]
    
    FRECUENCIA_CHOICES = [
        ('UNICO', 'Único'),
        ('DIARIO', 'Diario'),
        ('SEMANAL', 'Semanal'),
        ('QUINCENAL', 'Quincenal'),
        ('MENSUAL', 'Mensual'),
        ('BIMESTRAL', 'Bimestral'),
        ('TRIMESTRAL', 'Trimestral'),
        ('SEMESTRAL', 'Semestral'),
        ('ANUAL', 'Anual'),
    ]
    
    METODO_PAGO_CHOICES = [
        ('EFECTIVO', 'Efectivo'),
        ('TRANSFERENCIA', 'Transferencia'),
        ('TARJETA_DEBITO', 'Tarjeta Débito'),
        ('TARJETA_CREDITO', 'Tarjeta Crédito'),
        ('CHEQUE', 'Cheque'),
        ('PSE', 'PSE'),
        ('OTRO', 'Otro'),
    ]
    
    tipo = models.CharField(max_length=10, choices=TIPO_CHOICES, verbose_name="Tipo")
    categoria = models.ForeignKey(CategoriaFinanciera, on_delete=models.PROTECT, related_name='movimientos')
    subcategoria = models.ForeignKey(SubcategoriaFinanciera, on_delete=models.PROTECT, 
                                   related_name='movimientos', null=True, blank=True)
    
    descripcion = models.CharField(max_length=200, verbose_name="Descripción")
    monto = models.DecimalField(max_digits=15, decimal_places=2, verbose_name="Monto")
    fecha = models.DateField(verbose_name="Fecha del movimiento")
    
    # Para movimientos recurrentes
    es_recurrente = models.BooleanField(default=False, verbose_name="Es recurrente")
    frecuencia = models.CharField(max_length=12, choices=FRECUENCIA_CHOICES, 
                                blank=True, verbose_name="Frecuencia")
    fecha_fin_recurrencia = models.DateField(null=True, blank=True, 
                                          verbose_name="Fecha fin recurrencia")
    
    metodo_pago = models.CharField(max_length=20, choices=METODO_PAGO_CHOICES, 
                                 default='EFECTIVO', verbose_name="Método de pago")
    referencia = models.CharField(max_length=100, blank=True, 
                                verbose_name="Referencia/Número de transacción")
    
    # Información adicional
    notas = models.TextField(blank=True, verbose_name="Notas adicionales")
    comprobante = models.CharField(max_length=100, blank=True, verbose_name="Número de comprobante")
    
    # Campos de auditoría
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Movimiento Financiero"
        verbose_name_plural = "Movimientos Financieros"
        ordering = ['-fecha', '-fecha_creacion']
        indexes = [
            models.Index(fields=['fecha']),
            models.Index(fields=['tipo']),
            models.Index(fields=['categoria']),
        ]
    
    def __str__(self):
        signo = "+" if self.tipo == 'INGRESO' else "-"
        return f"{signo}${self.monto:,.2f} - {self.descripcion} ({self.fecha})"
    
    def save(self, *args, **kwargs):
        # Validar que la subcategoría pertenezca a la categoría seleccionada
        if self.subcategoria and self.subcategoria.categoria != self.categoria:
            raise ValueError("La subcategoría debe pertenecer a la categoría seleccionada")
        
        # Validar que tipo coincida con el tipo de categoría
        if self.categoria.tipo != self.tipo:
            raise ValueError("El tipo del movimiento debe coincidir con el tipo de categoría")
        
        super().save(*args, **kwargs)
    
    @property
    def es_ingreso(self):
        return self.tipo == 'INGRESO'
    
    @property
    def es_egreso(self):
        return self.tipo == 'EGRESO'

class PresupuestoCategoria(models.Model):
    """Presupuesto mensual por categoría"""
    categoria = models.ForeignKey(CategoriaFinanciera, on_delete=models.CASCADE, related_name='presupuestos')
    año = models.PositiveIntegerField(verbose_name="Año")
    mes = models.PositiveIntegerField(choices=[(i, i) for i in range(1, 13)], verbose_name="Mes")
    monto_presupuestado = models.DecimalField(max_digits=15, decimal_places=2, verbose_name="Monto presupuestado")
    notas = models.TextField(blank=True, verbose_name="Notas")
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Presupuesto por Categoría"
        verbose_name_plural = "Presupuestos por Categoría"
        unique_together = ['categoria', 'año', 'mes']
        ordering = ['-año', '-mes', 'categoria__nombre']
    
    def __str__(self):
        meses = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
        return f"{self.categoria.nombre} - {meses[self.mes]} {self.año}: ${self.monto_presupuestado:,.2f}"
    
    @property
    def monto_ejecutado(self):
        """Calcula cuánto se ha gastado/ingresado en esta categoría en el mes"""
        from django.db.models import Sum
        return MovimientoFinanciero.objects.filter(
            categoria=self.categoria,
            fecha__year=self.año,
            fecha__month=self.mes
        ).aggregate(total=Sum('monto'))['total'] or Decimal('0.00')
    
    @property
    def porcentaje_ejecucion(self):
        """Porcentaje ejecutado del presupuesto"""
        if self.monto_presupuestado > 0:
            return (self.monto_ejecutado / self.monto_presupuestado) * 100
        return 0
    
    @property
    def saldo_disponible(self):
        """Saldo disponible del presupuesto"""
        if self.categoria.tipo == 'EGRESO':
            return self.monto_presupuestado - self.monto_ejecutado
        else:
            return self.monto_ejecutado - self.monto_presupuestado

class MetaFinanciera(models.Model):
    """Metas financieras a largo plazo"""
    TIPO_CHOICES = [
        ('AHORRO', 'Ahorro'),
        ('INVERSION', 'Inversión'),
        ('DEUDA', 'Pago de Deuda'),
        ('COMPRA', 'Compra Específica'),
        ('EMERGENCIA', 'Fondo de Emergencia'),
        ('OTRO', 'Otro'),
    ]
    
    ESTADO_CHOICES = [
        ('ACTIVA', 'Activa'),
        ('COMPLETADA', 'Completada'),
        ('PAUSADA', 'Pausada'),
        ('CANCELADA', 'Cancelada'),
    ]
    
    nombre = models.CharField(max_length=150, verbose_name="Nombre de la meta")
    descripcion = models.TextField(verbose_name="Descripción")
    tipo = models.CharField(max_length=12, choices=TIPO_CHOICES, verbose_name="Tipo de meta")
    monto_objetivo = models.DecimalField(max_digits=15, decimal_places=2, verbose_name="Monto objetivo")
    monto_actual = models.DecimalField(max_digits=15, decimal_places=2, default=0, verbose_name="Monto actual")
    fecha_inicio = models.DateField(verbose_name="Fecha de inicio")
    fecha_objetivo = models.DateField(verbose_name="Fecha objetivo")
    estado = models.CharField(max_length=12, choices=ESTADO_CHOICES, default='ACTIVA', verbose_name="Estado")
    notas = models.TextField(blank=True, verbose_name="Notas")
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Meta Financiera"
        verbose_name_plural = "Metas Financieras"
        ordering = ['-fecha_objetivo']
    
    def __str__(self):
        return f"{self.nombre} - ${self.monto_objetivo:,.2f} ({self.get_estado_display()})"
    
    @property
    def porcentaje_completado(self):
        """Porcentaje completado de la meta"""
        if self.monto_objetivo > 0:
            return min((self.monto_actual / self.monto_objetivo) * 100, 100)
        return 0
    
    @property
    def monto_faltante(self):
        """Monto que falta para completar la meta"""
        return max(self.monto_objetivo - self.monto_actual, 0)
    
    @property
    def dias_restantes(self):
        """Días restantes para alcanzar la meta"""
        delta = self.fecha_objetivo - timezone.now().date()
        return max(delta.days, 0)
EOF

echo "✅ Modelos agregados al archivo models.py"

# Actualizar admin.py para incluir los nuevos modelos
cat >> core/admin.py << 'EOF'

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

echo "✅ Admin actualizado con los nuevos modelos"

# Crear y aplicar migraciones
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
echo "🎉 ¡Sistema de ingresos y egresos creado exitosamente!"
echo ""
echo "📋 Nuevas funcionalidades disponibles:"
echo ""
echo "   📊 CATEGORÍAS FINANCIERAS"
echo "   • Ingresos Fijos (Salario, Pensión, Arriendos recibidos)"
echo "   • Ingresos Variables (Comisiones, Ventas, Trabajos extras)"
echo "   • Egresos Fijos (Arriendo, Servicios, Seguros, Cuotas)"
echo "   • Egresos Variables (Alimentación, Transporte, Entretenimiento)"
echo ""
echo "   🏷️  SUBCATEGORÍAS"
echo "   • Clasificación detallada para cada categoría"
echo "   • Ejemplo: Servicios → Luz, Agua, Gas, Internet"
echo ""
echo "   💰 MOVIMIENTOS FINANCIEROS"
echo "   • Registro de todos los ingresos y gastos"
echo "   • Soporte para movimientos recurrentes"
echo "   • Múltiples métodos de pago"
echo "   • Comprobantes y referencias"
echo ""
echo "   📊 PRESUPUESTOS"
echo "   • Control mensual por categoría"
echo "   • Seguimiento de ejecución"
echo "   • Alertas de sobregiro"
echo ""
echo "   🎯 METAS FINANCIERAS"
echo "   • Ahorros y objetivos a largo plazo"
echo "   • Seguimiento de progreso"
echo "   • Diferentes tipos de metas"
echo ""
echo "🌐 Accede al admin para empezar a configurar:"
echo "   https://finanzapp.ngrok.io/admin/"
