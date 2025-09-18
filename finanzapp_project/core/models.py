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
