#!/bin/bash

echo "Creando estructura completa del frontend Node.js..."

cd ~/finanzApp-dev

# Crear directorio del frontend
mkdir -p finanzapp-frontend
cd finanzapp-frontend

# Crear package.json
cat > package.json << 'EOF'
{
  "name": "finanzapp-frontend",
  "version": "1.0.0",
  "description": "Frontend moderno para FinanzApp",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "axios": "^1.5.0",
    "ejs": "^3.1.9",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

# Crear servidor principal
cat > server.js << 'EOF'
const express = require('express');
const axios = require('axios');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 3000;
const API_BASE_URL = 'http://localhost:8090/api';

// Middleware
app.use(cors());
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// Función helper para manejar errores de API
async function fetchFromAPI(endpoint) {
    try {
        const response = await axios.get(`${API_BASE_URL}${endpoint}`);
        return response.data;
    } catch (error) {
        console.error(`Error fetching ${endpoint}:`, error.message);
        return null;
    }
}

// Ruta principal - Dashboard
app.get('/', async (req, res) => {
    const stats = await fetchFromAPI('/dashboard/stats/') || {};
    const movimientos = await fetchFromAPI('/dashboard/movimientos/') || [];
    const graficos = await fetchFromAPI('/dashboard/graficos/') || {};
    
    res.render('dashboard', {
        title: 'Dashboard - FinanzApp',
        stats,
        movimientos,
        graficos
    });
});

// Ruta para deudores
app.get('/deudores', async (req, res) => {
    const data = await fetchFromAPI('/deudores/') || [];
    const deudores = data.results || data;
    
    res.render('deudores', {
        title: 'Deudores - FinanzApp',
        deudores
    });
});

// Ruta para mis deudas
app.get('/mis-deudas', async (req, res) => {
    const data = await fetchFromAPI('/mis-deudas/') || [];
    const deudas = data.results || data;
    
    res.render('mis-deudas', {
        title: 'Mis Deudas - FinanzApp',
        deudas
    });
});

// Ruta para movimientos financieros
app.get('/movimientos', async (req, res) => {
    const data = await fetchFromAPI('/movimientos/') || [];
    const movimientos = data.results || data;
    
    res.render('movimientos', {
        title: 'Movimientos - FinanzApp',
        movimientos
    });
});

// Ruta para categorías
app.get('/categorias', async (req, res) => {
    const data = await fetchFromAPI('/categorias/') || [];
    const categorias = data.results || data;
    
    res.render('categorias', {
        title: 'Categorías - FinanzApp',
        categorias
    });
});

// API routes para AJAX
app.get('/api/stats', async (req, res) => {
    const stats = await fetchFromAPI('/dashboard/stats/');
    res.json(stats || {});
});

app.listen(PORT, () => {
    console.log(`\\n🚀 Frontend Node.js iniciado!`);
    console.log(`📍 Dirección local: http://localhost:${PORT}`);
    console.log(`🔌 Conectado a API Django: ${API_BASE_URL}`);
    console.log(`\\n📋 Rutas disponibles:`);
    console.log(`   • http://localhost:${PORT}/ - Dashboard`);
    console.log(`   • http://localhost:${PORT}/deudores - Gestión de deudores`);
    console.log(`   • http://localhost:${PORT}/mis-deudas - Mis deudas`);
    console.log(`   • http://localhost:${PORT}/movimientos - Movimientos financieros`);
    console.log(`   • http://localhost:${PORT}/categorias - Categorías`);
});
EOF

# Crear directorio de vistas
mkdir -p views

# Crear layout base
cat > views/layout.ejs << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="/css/style.css" rel="stylesheet">
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="/">
                <i class="fas fa-coins me-2"></i>FinanzApp
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="/"><i class="fas fa-tachometer-alt me-1"></i>Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/deudores"><i class="fas fa-users me-1"></i>Deudores</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/mis-deudas"><i class="fas fa-credit-card me-1"></i>Mis Deudas</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/movimientos"><i class="fas fa-exchange-alt me-1"></i>Movimientos</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/categorias"><i class="fas fa-tags me-1"></i>Categorías</a>
                    </li>
                </ul>
                <ul class="navbar-nav">
                    <li class="nav-item">
                        <a class="nav-link" href="http://localhost:8090/admin/" target="_blank">
                            <i class="fas fa-cog me-1"></i>Admin
                        </a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Contenido principal -->
    <main class="container mt-4">
        <%- body %>
    </main>

    <!-- Scripts -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="/js/app.js"></script>
</body>
</html>
EOF

# Crear vista del dashboard
cat > views/dashboard.ejs << 'EOF'
<% layout('layout') -%>

<div class="row">
    <div class="col-12">
        <h1 class="mb-4"><i class="fas fa-tachometer-alt me-2"></i>Dashboard Financiero</h1>
    </div>
</div>

<!-- Tarjetas de estadísticas -->
<div class="row mb-4">
    <div class="col-md-3">
        <div class="card bg-success text-white">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h6 class="card-title">Por Cobrar</h6>
                        <h4>$<%= stats.total_por_cobrar?.toLocaleString() || '0' %></h4>
                    </div>
                    <div class="align-self-center">
                        <i class="fas fa-arrow-down fa-2x"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="card bg-danger text-white">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h6 class="card-title">Por Pagar</h6>
                        <h4>$<%= stats.total_por_pagar?.toLocaleString() || '0' %></h4>
                    </div>
                    <div class="align-self-center">
                        <i class="fas fa-arrow-up fa-2x"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="card bg-primary text-white">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h6 class="card-title">Ingresos Mes</h6>
                        <h4>$<%= stats.ingresos_mes?.toLocaleString() || '0' %></h4>
                    </div>
                    <div class="align-self-center">
                        <i class="fas fa-plus fa-2x"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="card bg-warning text-white">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h6 class="card-title">Egresos Mes</h6>
                        <h4>$<%= stats.egresos_mes?.toLocaleString() || '0' %></h4>
                    </div>
                    <div class="align-self-center">
                        <i class="fas fa-minus fa-2x"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Gráficos y movimientos recientes -->
<div class="row">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <h5><i class="fas fa-chart-line me-2"></i>Ingresos vs Egresos</h5>
            </div>
            <div class="card-body">
                <canvas id="chartIngresos" height="100"></canvas>
            </div>
        </div>
    </div>
    
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <h5><i class="fas fa-history me-2"></i>Movimientos Recientes</h5>
            </div>
            <div class="card-body">
                <% if (movimientos && movimientos.length > 0) { %>
                    <% movimientos.slice(0, 5).forEach(function(mov) { %>
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <div>
                                <small class="text-muted"><%= mov.fecha %></small><br>
                                <span class="fw-bold"><%= mov.descripcion %></span>
                            </div>
                            <span class="badge bg-<%= mov.tipo === 'INGRESO' ? 'success' : 'danger' %>">
                                <%= mov.tipo === 'INGRESO' ? '+' : '-' %>$<%= mov.monto?.toLocaleString() || '0' %>
                            </span>
                        </div>
                    <% }); %>
                <% } else { %>
                    <p class="text-muted">No hay movimientos recientes</p>
                <% } %>
            </div>
        </div>
    </div>
</div>

<script>
// Gráfico de ingresos vs egresos
document.addEventListener('DOMContentLoaded', function() {
    const ctx = document.getElementById('chartIngresos').getContext('2d');
    
    // Datos de ejemplo (en producción vendrían de la API)
    new Chart(ctx, {
        type: 'line',
        data: {
            labels: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio'],
            datasets: [{
                label: 'Ingresos',
                data: [<%= stats.ingresos_mes || 0 %>, 0, 0, 0, 0, 0],
                borderColor: 'rgb(75, 192, 192)',
                backgroundColor: 'rgba(75, 192, 192, 0.2)',
                tension: 0.1
            }, {
                label: 'Egresos',
                data: [<%= stats.egresos_mes || 0 %>, 0, 0, 0, 0, 0],
                borderColor: 'rgb(255, 99, 132)',
                backgroundColor: 'rgba(255, 99, 132, 0.2)',
                tension: 0.1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });
});
</script>
EOF

# Crear directorio de archivos estáticos
mkdir -p public/css
mkdir -p public/js

# Crear CSS personalizado
cat > public/css/style.css << 'EOF'
/* Estilos personalizados para FinanzApp */

body {
    background-color: #f8f9fa;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.navbar-brand {
    font-weight: bold;
    font-size: 1.5rem;
}

.card {
    border: none;
    border-radius: 15px;
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.1);
    transition: transform 0.2s ease-in-out;
}

.card:hover {
    transform: translateY(-2px);
}

.card-header {
    background-color: transparent;
    border-bottom: 1px solid rgba(0, 0, 0, 0.1);
    font-weight: 600;
}

.btn {
    border-radius: 8px;
    font-weight: 500;
}

.badge {
    font-size: 0.85em;
}

.table {
    background-color: white;
    border-radius: 10px;
    overflow: hidden;
}

.navbar-nav .nav-link {
    font-weight: 500;
    transition: color 0.2s ease;
}

.navbar-nav .nav-link:hover {
    color: rgba(255, 255, 255, 0.8);
}

/* Responsivo */
@media (max-width: 768px) {
    .card {
        margin-bottom: 1rem;
    }
    
    .navbar-brand {
        font-size: 1.25rem;
    }
}
EOF

# Crear JavaScript principal
cat > public/js/app.js << 'EOF'
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
EOF

echo ""
echo "Estructura del frontend Node.js creada exitosamente!"
echo ""
echo "Archivos creados:"
echo "📁 finanzapp-frontend/"
echo "  📄 package.json - Configuración del proyecto"
echo "  📄 server.js - Servidor Express principal"
echo "  📁 views/ - Templates EJS"
echo "    📄 layout.ejs - Layout base"
echo "    📄 dashboard.ejs - Dashboard principal"
echo "  📁 public/ - Archivos estáticos"
echo "    📁 css/"
echo "      📄 style.css - Estilos personalizados"
echo "    📁 js/"
echo "      📄 app.js - JavaScript principal"
echo ""
echo "Para iniciar el frontend:"
echo "1. cd finanzapp-frontend"
echo "2. npm install"
echo "3. npm start"
echo ""
echo "El frontend estará disponible en http://localhost:3000"
