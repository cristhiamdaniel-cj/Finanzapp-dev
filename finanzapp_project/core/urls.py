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
