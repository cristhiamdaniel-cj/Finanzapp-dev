#!/bin/bash

echo "💳 Agregando modelos para gestionar mis propias deudas..."

cd ~/finanzApp-dev/finanzapp_project
source ../venv_finanzapp/bin/activate

# Agregar los nuevos modelos al archivo models.py existente
cat >> core/models.py << 'EOF'

# ===== MODELOS PARA MIS PROPIAS DEUDAS =====

class Acreedor(models.Model):
    """Entidades a las que les debo dinero (bancos, personas, empresas)"""
    TIPO_CHOICES = [
        ('BANCO', 'Banco'),
        ('PERSONA', 'Persona Natural'),
        ('EMPRESA', 'Empresa'),
        ('GOBIERNO', 'Entidad Gubernamental'),
        ('OTRO', 'Otro'),
    ]
    
    nombre = models.CharField(max_length=200, verbose_name="Nombre del acreedor")
    tipo = models.CharField(max_length=10, choices=TIPO_CHOICES, default='BANCO', verbose_name="Tipo de acreedor")
    documento = models.CharField(max_length=50, blank=True, verbose_name="NIT/Documento")
    telefono = models.CharField(max_length=20, blank=True, verbose_name="Teléfono")
    email = models.EmailField(blank=True, verbose_name="Correo electrónico")
    direccion = models.TextField(blank=True, verbose_name="Dirección")
    contacto_principal = models.CharField(max_length=100, blank=True, verbose_name="Contacto principal")
    observaciones = models.TextField(blank=True, verbose_name="Observaciones")
    activo = models.BooleanField(default=True, verbose_name="Activo")
    fecha_registro = models.DateTimeField(auto_now_add=True, verbose_name="Fecha de registro")
    
    class Meta:
        verbose_name = "Acreedor"
        verbose_name_plural = "Acreedores"
        ordering = ['nombre']
    
    def __str__(self):
        return f"{self.nombre} ({self.get_tipo_display()})"
    
    @property
    def total_deuda_pendiente(self):
        """Calcula el total que le debo a este acreedor"""
        return self.mis_deudas.filter(estado__in=['PENDIENTE', 'VENCIDA', 'PARCIAL']).aggregate(
            total=models.Sum('saldo_pendiente')
        )['total'] or Decimal('0.00')

class MiDeuda(models.Model):
    """Deudas que yo tengo con terceros"""
    ESTADO_CHOICES = [
        ('PENDIENTE', 'Pendiente'),
        ('PAGADA', 'Pagada'),
        ('VENCIDA', 'Vencida'),
        ('PARCIAL', 'Pago Parcial'),
        ('REFINANCIADA', 'Refinanciada'),
        ('CONDONADA', 'Condonada'),
    ]
    
    TIPO_CHOICES = [
        ('PRESTAMO', 'Préstamo Personal'),
        ('TARJETA_CREDITO', 'Tarjeta de Crédito'),
        ('HIPOTECA', 'Hipoteca'),
        ('VEHICULO', 'Crédito Vehículo'),
        ('COMERCIAL', 'Crédito Comercial'),
        ('LIBRANZA', 'Crédito Libranza'),
        ('PERSONAL', 'Deuda Personal'),
        ('SERVICIO', 'Servicio (Agua, Luz, etc.)'),
        ('IMPUESTO', 'Impuesto'),
        ('OTRO', 'Otro'),
    ]
    
    CATEGORIA_CHOICES = [
        ('ALTA', 'Prioridad Alta'),
        ('MEDIA', 'Prioridad Media'),
        ('BAJA', 'Prioridad Baja'),
    ]
    
    acreedor = models.ForeignKey(Acreedor, on_delete=models.CASCADE, related_name='mis_deudas')
    numero_cuenta = models.CharField(max_length=50, blank=True, verbose_name="Número de cuenta/contrato")
    tipo_deuda = models.CharField(max_length=20, choices=TIPO_CHOICES, verbose_name="Tipo de deuda")
    concepto = models.CharField(max_length=300, verbose_name="Concepto/Descripción")
    monto_original = models.DecimalField(max_digits=15, decimal_places=2, verbose_name="Monto original")
    saldo_pendiente = models.DecimalField(max_digits=15, decimal_places=2, verbose_name="Saldo pendiente")
    tasa_interes = models.DecimalField(max_digits=5, decimal_places=2, default=0, verbose_name="Tasa de interés anual (%)")
    fecha_contrato = models.DateField(verbose_name="Fecha del contrato")
    fecha_vencimiento = models.DateField(verbose_name="Fecha de vencimiento")
    cuota_mensual = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, verbose_name="Cuota mensual")
    plazo_meses = models.PositiveIntegerField(null=True, blank=True, verbose_name="Plazo en meses")
    prioridad = models.CharField(max_length=10, choices=CATEGORIA_CHOICES, default='MEDIA', verbose_name="Prioridad")
    estado = models.CharField(max_length=15, choices=ESTADO_CHOICES, default='PENDIENTE')
    observaciones = models.TextField(blank=True, verbose_name="Observaciones")
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Mi Deuda"
        verbose_name_plural = "Mis Deudas"
        ordering = ['-fecha_contrato']
    
    def __str__(self):
        return f"{self.acreedor.nombre} - {self.concepto} - ${self.saldo_pendiente:,.2f}"
    
    def save(self, *args, **kwargs):
        # Si es nueva deuda, el saldo pendiente es igual al monto original
        if not self.pk:
            self.saldo_pendiente = self.monto_original
        
        # Actualizar estado según fecha de vencimiento
        if self.fecha_vencimiento < timezone.now().date() and self.estado == 'PENDIENTE':
            self.estado = 'VENCIDA'
        
        super().save(*args, **kwargs)
    
    @property
    def dias_hasta_vencimiento(self):
        """Días hasta el vencimiento (negativo si ya venció)"""
        delta = self.fecha_vencimiento - timezone.now().date()
        return delta.days
    
    @property
    def porcentaje_pagado(self):
        """Porcentaje pagado de la deuda"""
        if self.monto_original > 0:
            pagado = self.monto_original - self.saldo_pendiente
            return (pagado / self.monto_original) * 100
        return 0
    
    @property
    def interes_mensual(self):
        """Calcula el interés mensual aproximado"""
        if self.tasa_interes > 0:
            return (self.saldo_pendiente * self.tasa_interes / 100) / 12
        return Decimal('0.00')

class MiPago(models.Model):
    """Pagos que hago a mis deudas"""
    mi_deuda = models.ForeignKey(MiDeuda, on_delete=models.CASCADE, related_name='mis_pagos')
    monto_pago = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Monto del pago")
    monto_capital = models.DecimalField(max_digits=12, decimal_places=2, default=0, verbose_name="Monto aplicado a capital")
    monto_interes = models.DecimalField(max_digits=12, decimal_places=2, default=0, verbose_name="Monto aplicado a intereses")
    fecha_pago = models.DateField(verbose_name="Fecha del pago")
    metodo_pago = models.CharField(max_length=50, verbose_name="Método de pago",
                                   choices=[
                                       ('EFECTIVO', 'Efectivo'),
                                       ('TRANSFERENCIA', 'Transferencia Bancaria'),
                                       ('DEBITO_AUTOMATICO', 'Débito Automático'),
                                       ('CHEQUE', 'Cheque'),
                                       ('PSE', 'PSE'),
                                       ('TARJETA', 'Tarjeta de Crédito/Débito'),
                                       ('OTRO', 'Otro'),
                                   ])
    numero_transaccion = models.CharField(max_length=100, blank=True, verbose_name="Número de transacción")
    comprobante = models.CharField(max_length=100, blank=True, verbose_name="Número de comprobante")
    observaciones = models.TextField(blank=True, verbose_name="Observaciones")
    fecha_registro = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Mi Pago"
        verbose_name_plural = "Mis Pagos"
        ordering = ['-fecha_pago']
    
    def __str__(self):
        return f"Pago ${self.monto_pago:,.2f} - {self.mi_deuda.acreedor.nombre} - {self.fecha_pago}"
    
    def save(self, *args, **kwargs):
        # Si no se especifica distribución capital/interés, todo va a capital
        if self.monto_capital == 0 and self.monto_interes == 0:
            self.monto_capital = self.monto_pago
        
        super().save(*args, **kwargs)
        # Actualizar el saldo de la deuda
        self.actualizar_saldo_deuda()
    
    def actualizar_saldo_deuda(self):
        """Actualiza el saldo pendiente de la deuda"""
        total_pagos_capital = self.mi_deuda.mis_pagos.aggregate(
            total=models.Sum('monto_capital')
        )['total'] or Decimal('0.00')
        
        self.mi_deuda.saldo_pendiente = self.mi_deuda.monto_original - total_pagos_capital
        
        if self.mi_deuda.saldo_pendiente <= 0:
            self.mi_deuda.estado = 'PAGADA'
            self.mi_deuda.saldo_pendiente = Decimal('0.00')
        elif self.mi_deuda.saldo_pendiente < self.mi_deuda.monto_original:
            self.mi_deuda.estado = 'PARCIAL'
        
        self.mi_deuda.save()

class RecordatorioDeuda(models.Model):
    """Recordatorios para pagos de deudas"""
    mi_deuda = models.ForeignKey(MiDeuda, on_delete=models.CASCADE, related_name='recordatorios')
    fecha_recordatorio = models.DateField(verbose_name="Fecha del recordatorio")
    dias_anticipacion = models.PositiveIntegerField(default=5, verbose_name="Días de anticipación")
    mensaje = models.TextField(verbose_name="Mensaje del recordatorio")
    activo = models.BooleanField(default=True, verbose_name="Activo")
    enviado = models.BooleanField(default=False, verbose_name="Enviado")
    fecha_envio = models.DateTimeField(null=True, blank=True, verbose_name="Fecha de envío")
    
    class Meta:
        verbose_name = "Recordatorio de Deuda"
        verbose_name_plural = "Recordatorios de Deudas"
        ordering = ['fecha_recordatorio']
    
    def __str__(self):
        return f"Recordatorio {self.mi_deuda.acreedor.nombre} - {self.fecha_recordatorio}"
EOF

echo "✅ Modelos agregados al archivo models.py"

# Actualizar admin.py para incluir los nuevos modelos
cat >> core/admin.py << 'EOF'

# ===== ADMIN PARA MIS DEUDAS =====

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
EOF

echo "✅ Admin actualizado con los nuevos modelos"

# Crear y aplicar migraciones
echo "🔄 Creando migraciones..."
python manage.py makemigrations core

echo "📦 Aplicando migraciones..."
python manage.py migrate

echo "✅ Verificando configuración..."
python manage.py check

echo ""
echo "🎉 ¡Nuevos modelos para gestionar tus deudas agregados exitosamente!"
echo ""
echo "📋 Nuevas funcionalidades disponibles en el admin:"
echo "   • Acreedores - Bancos, personas y empresas a quienes les debes"
echo "   • Mis Deudas - Tus deudas con información completa"
echo "   • Mis Pagos - Pagos que realizas a tus deudas"
echo "   • Recordatorios - Alertas para no olvidar pagos"
echo ""
echo "💡 Tipos de deuda soportados:"
echo "   • Préstamos personales"
echo "   • Tarjetas de crédito"
echo "   • Hipotecas"
echo "   • Créditos vehiculares"
echo "   • Servicios públicos"
echo "   • Impuestos"
echo "   • Y más..."
echo ""
echo "🚀 Reinicia el servidor para ver los cambios en el admin."