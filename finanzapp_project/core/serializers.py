from rest_framework import serializers
from .models import *

class DeudorSerializer(serializers.ModelSerializer):
    total_deuda = serializers.ReadOnlyField()
    
    class Meta:
        model = Deudor
        fields = '__all__'

class DeudaSerializer(serializers.ModelSerializer):
    deudor_nombre = serializers.CharField(source='deudor.nombre', read_only=True)
    
    class Meta:
        model = Deuda
        fields = '__all__'

class AcreedorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Acreedor
        fields = '__all__'

class MiDeudaSerializer(serializers.ModelSerializer):
    acreedor_nombre = serializers.CharField(source='acreedor.nombre', read_only=True)
    
    class Meta:
        model = MiDeuda
        fields = '__all__'

class CategoriaFinancieraSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategoriaFinanciera
        fields = '__all__'

class MovimientoFinancieroSerializer(serializers.ModelSerializer):
    categoria_nombre = serializers.CharField(source='categoria.nombre', read_only=True)
    
    class Meta:
        model = MovimientoFinanciero
        fields = '__all__'
