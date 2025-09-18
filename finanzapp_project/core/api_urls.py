from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import api_views

router = DefaultRouter()
router.register(r'deudores', api_views.DeudorViewSet)
router.register(r'deudas', api_views.DeudaViewSet)
router.register(r'acreedores', api_views.AcreedorViewSet)
router.register(r'mis-deudas', api_views.MiDeudaViewSet)
router.register(r'categorias', api_views.CategoriaFinancieraViewSet)
router.register(r'movimientos', api_views.MovimientoFinancieroViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/stats/', api_views.dashboard_stats, name='dashboard-stats'),
    path('dashboard/movimientos/', api_views.movimientos_recientes, name='movimientos-recientes'),
    path('dashboard/graficos/', api_views.graficos_dashboard, name='graficos-dashboard'),
]
