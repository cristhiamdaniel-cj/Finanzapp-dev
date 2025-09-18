// JavaScript principal para FinanzApp

document.addEventListener('DOMContentLoaded', function() {
    // Inicializar tooltips de Bootstrap
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Función para formatear números como moneda
    window.formatCurrency = function(amount) {
        return new Intl.NumberFormat('es-CO', {
            style: 'currency',
            currency: 'COP'
        }).format(amount);
    };

    // Función para actualizar estadísticas en tiempo real
    window.updateStats = async function() {
        try {
            const response = await fetch('/api/stats');
            const stats = await response.json();
            
            // Actualizar elementos si existen
            const elements = {
                'total_por_cobrar': stats.total_por_cobrar,
                'total_por_pagar': stats.total_por_pagar,
                'ingresos_mes': stats.ingresos_mes,
                'egresos_mes': stats.egresos_mes
            };
            
            Object.keys(elements).forEach(key => {
                const element = document.getElementById(key);
                if (element) {
                    element.textContent = formatCurrency(elements[key] || 0);
                }
            });
        } catch (error) {
            console.error('Error actualizando estadísticas:', error);
        }
    };

    // Actualizar estadísticas cada 30 segundos
    setInterval(updateStats, 30000);
    
    console.log('FinanzApp Frontend cargado correctamente');
});
