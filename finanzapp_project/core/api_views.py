from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db.models import Sum, Count
from django.utils import timezone
from datetime import datetime, timedelta
from decimal import Decimal
from .models import *
from .serializers import *

class DeudorViewSet(viewsets.ModelViewSet):
    queryset = Deudor.objects.filter(activo=True)
    serializer_class = DeudorSerializer

class DeudaViewSet(viewsets.ModelViewSet):
    queryset = Deuda.objects.all()
    serializer_class = DeudaSerializer

class AcreedorViewSet(viewsets.ModelViewSet):
    queryset = Acreedor.objects.filter(activo=True)
    serializer_class = AcreedorSerializer

class MiDeudaViewSet(viewsets.ModelViewSet):
    queryset = MiDeuda.objects.all()
    serializer_class = MiDeudaSerializer

class CategoriaFinancieraViewSet(viewsets.ModelViewSet):
    queryset = CategoriaFinanciera.objects.filter(activo=True)
    serializer_class = CategoriaFinancieraSerializer

class MovimientoFinancieroViewSet(viewsets.ModelViewSet):
    queryset = MovimientoFinanciero.objects.all()
    serializer_class = MovimientoFinancieroSerializer

@api_view(['GET'])
def dashboard_stats(request):
    """Estadísticas para el dashboard"""
    hoy = timezone.now().date()
    mes_actual = hoy.month
    ano_actual = hoy.year
    
    try:
        # Estadísticas generales
        total_deudores = Deudor.objects.filter(activo=True).count()
        
        total_por_cobrar = Deuda.objects.filter(
            estado__in=['PENDIENTE', 'VENCIDA', 'PARCIAL']
        ).aggregate(total=Sum('monto_pendiente'))['total'] or Decimal('0')
        
        total_acreedores = Acreedor.objects.filter(activo=True).count()
        
        total_por_pagar = MiDeuda.objects.filter(
            estado__in=['PENDIENTE', 'VENCIDA', 'PARCIAL']
        ).aggregate(total=Sum('saldo_pendiente'))['total'] or Decimal('0')
        
        # Movimientos del mes actual
        ingresos_mes = MovimientoFinanciero.objects.filter(
            tipo='INGRESO', 
            fecha__month=mes_actual, 
            fecha__year=ano_actual
        ).aggregate(total=Sum('monto'))['total'] or Decimal('0')
        
        egresos_mes = MovimientoFinanciero.objects.filter(
            tipo='EGRESO',
            fecha__month=mes_actual,
            fecha__year=ano_actual
        ).aggregate(total=Sum('monto'))['total'] or Decimal('0')
        
        # Deudas vencidas
        deudas_vencidas = Deuda.objects.filter(
            estado__in=['PENDIENTE', 'VENCIDA'],
            fecha_vencimiento__lt=hoy
        ).count()
        
        mis_deudas_vencidas = MiDeuda.objects.filter(
            estado__in=['PENDIENTE', 'VENCIDA'],
            fecha_vencimiento__lt=hoy
        ).count()
        
        stats = {
            'total_deudores': total_deudores,
            'total_por_cobrar': float(total_por_cobrar),
            'total_acreedores': total_acreedores,
            'total_por_pagar': float(total_por_pagar),
            'ingresos_mes': float(ingresos_mes),
            'egresos_mes': float(egresos_mes),
            'deudas_vencidas': deudas_vencidas,
            'mis_deudas_vencidas': mis_deudas_vencidas,
        }
        
        return Response(stats)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def movimientos_recientes(request):
    """Últimos movimientos financieros"""
    try:
        movimientos = MovimientoFinanciero.objects.order_by('-fecha', '-fecha_creacion')[:10]
        serializer = MovimientoFinancieroSerializer(movimientos, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def graficos_dashboard(request):
    """Datos para gráficos del dashboard"""
    try:
        hoy = timezone.now().date()
        
        # Ingresos vs Egresos últimos 6 meses
        meses = []
        for i in range(6):
            mes = hoy.replace(day=1) - timedelta(days=30*i)
            
            ingresos = MovimientoFinanciero.objects.filter(
                tipo='INGRESO',
                fecha__month=mes.month,
                fecha__year=mes.year
            ).aggregate(total=Sum('monto'))['total'] or Decimal('0')
            
            egresos = MovimientoFinanciero.objects.filter(
                tipo='EGRESO',
                fecha__month=mes.month,
                fecha__year=mes.year
            ).aggregate(total=Sum('monto'))['total'] or Decimal('0')
            
            meses.append({
                'mes': mes.strftime('%B %Y'),
                'ingresos': float(ingresos),
                'egresos': float(egresos)
            })
        
        # Gastos por categoría del mes actual
        gastos_categoria = MovimientoFinanciero.objects.filter(
            tipo='EGRESO',
            fecha__month=hoy.month,
            fecha__year=hoy.year
        ).values('categoria__nombre').annotate(
            total=Sum('monto')
        ).order_by('-total')[:5]
        
        return Response({
            'ingresos_egresos_meses': meses,
            'gastos_por_categoria': [
                {
                    'categoria__nombre': item['categoria__nombre'],
                    'total': float(item['total'] or 0)
                } for item in gastos_categoria
            ]
        })
    except Exception as e:
        return Response({'error': str(e)}, status=500)
