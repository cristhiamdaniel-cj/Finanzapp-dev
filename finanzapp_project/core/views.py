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
