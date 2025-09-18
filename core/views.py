# core/views.py
from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

def home(request):
    """Vista principal de la aplicación financiera"""
    context = {
        'title': 'FinanzApp - Sistema Financiero',
        'version': '1.0.0',
        'server_info': 'Servidor: 192.168.0.101:8090'
    }
    return render(request, 'core/home.html', context)

def api_status(request):
    """API endpoint para verificar el estado del servicio"""
    return JsonResponse({
        'status': 'active',
        'service': 'finanzapp',
        'port': 8090,
        'ngrok_url': 'https://finanzapp.ngrok.io',
        'server': '192.168.0.101'
    })

@csrf_exempt
def api_test(request):
    """Endpoint de prueba para la API"""
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