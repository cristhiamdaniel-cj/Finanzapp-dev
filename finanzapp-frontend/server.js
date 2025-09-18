const express = require('express');
const axios = require('axios');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 8029;
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
