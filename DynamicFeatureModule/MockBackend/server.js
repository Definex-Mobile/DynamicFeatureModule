const express = require('express');
const cors = require('cors');
const path = require('path');
const crypto = require('crypto');
const fs = require('fs');

const app = express();
const PORT = 8000;

// Middleware
app.use(cors());
app.use(express.json());

// Logging middleware
app.use((req, res, next) => {
    console.log(`📥 ${req.method} ${req.url}`);
    next();
});

// Static files (zip downloads)
app.use('/downloads', express.static(path.join(__dirname, 'downloads')));

// Helper: Calculate SHA-256 checksum
function calculateChecksum(filePath) {
    try {
        const fileBuffer = fs.readFileSync(filePath);
        const hashSum = crypto.createHash('sha256');
        hashSum.update(fileBuffer);
        return hashSum.digest('hex');
    } catch (error) {
        console.error(`❌ Error calculating checksum for ${filePath}:`, error.message);
        return null;
    }
}

// Module metadata
const modules = [
    {
        id: "feature-payment",
        name: "Payment Module",
        version: "1.0.0",
        downloadUrl: `http://localhost:${PORT}/downloads/module-payment-v1.0.0.zip`,
        checksum: "",
        size: 0
    },
    {
        id: "feature-profile",
        name: "Profile Module",
        version: "1.1.0",
        downloadUrl: `http://localhost:${PORT}/downloads/module-profile-v1.1.0.zip`,
        checksum: "",
        size: 0
    }
];

// Calculate checksums on startup
function initializeModules() {
    console.log('\n🔍 Checking module files...\n');
    
    let allFilesExist = true;
    
    modules.forEach(module => {
        const fileName = `module-${module.id.replace('feature-', '')}-v${module.version}.zip`;
        const filePath = path.join(__dirname, 'downloads', fileName);
        
        if (fs.existsSync(filePath)) {
            const stats = fs.statSync(filePath);
            const checksum = calculateChecksum(filePath);
            
            if (checksum) {
                module.checksum = `sha256:${checksum}`;
                module.size = stats.size;
                console.log(`✅ ${module.name}`);
                console.log(`   File: ${fileName}`);
                console.log(`   Size: ${(stats.size / 1024).toFixed(2)} KB`);
                console.log(`   Checksum: ${module.checksum.substring(0, 20)}...`);
                console.log('');
            } else {
                console.log(`⚠️  ${module.name}: Checksum calculation failed`);
                allFilesExist = false;
            }
        } else {
            console.log(`❌ ${module.name}: File not found`);
            console.log(`   Expected: ${filePath}`);
            console.log('');
            allFilesExist = false;
        }
    });
    
    if (!allFilesExist) {
        console.log('⚠️  Some module files are missing!');
        console.log('📝 Run: node create-test-modules.js');
        console.log('');
    }
    
    return allFilesExist;
}

// API Routes

// GET /api/modules - Get all modules
app.get('/api/modules', (req, res) => {
    console.log('📤 Sending module list...');
    
    // Filter out modules without checksums
    const validModules = modules.filter(m => m.checksum && m.size > 0);
    
    if (validModules.length === 0) {
        console.log('⚠️  No valid modules available');
        return res.status(503).json({
            error: 'No modules available',
            message: 'Please run: node create-test-modules.js'
        });
    }
    
    console.log(`✅ Returning ${validModules.length} modules`);
    res.json({
        modules: validModules
    });
});

// GET /api/modules/:id - Get specific module
app.get('/api/modules/:id', (req, res) => {
    const moduleId = req.params.id;
    console.log(`📤 Request for module: ${moduleId}`);
    
    const module = modules.find(m => m.id === moduleId);
    
    if (module && module.checksum && module.size > 0) {
        console.log(`✅ Returning ${module.name}`);
        res.json(module);
    } else if (module) {
        console.log(`⚠️  Module ${moduleId} found but invalid`);
        res.status(503).json({
            error: 'Module not ready',
            message: 'Please run: node create-test-modules.js'
        });
    } else {
        console.log(`❌ Module ${moduleId} not found`);
        res.status(404).json({
            error: 'Module not found',
            moduleId: moduleId
        });
    }
});

// GET /api/test - Test endpoint
app.get('/api/test', (req, res) => {
    res.json({
        message: 'Backend is working!',
        timestamp: new Date().toISOString(),
        availableModules: modules.filter(m => m.checksum).length,
        allModules: modules.length
    });
});

// Health check
app.get('/health', (req, res) => {
    const validModules = modules.filter(m => m.checksum && m.size > 0);
    
    res.json({
        status: validModules.length > 0 ? 'ok' : 'degraded',
        timestamp: new Date().toISOString(),
        availableModules: validModules.length,
        totalModules: modules.length,
        ready: validModules.length === modules.length
    });
});

// Root
app.get('/', (req, res) => {
    res.json({
        message: 'DynamicFeatureModule Mock Backend',
        version: '1.0.0',
        status: 'running',
        endpoints: {
            modules: '/api/modules',
            module: '/api/modules/:id',
            test: '/api/test',
            health: '/health'
        }
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('❌ Server error:', err);
    res.status(500).json({
        error: 'Internal server error',
        message: err.message
    });
});

// Initialize and start server
const downloadsDir = path.join(__dirname, 'downloads');
if (!fs.existsSync(downloadsDir)) {
    fs.mkdirSync(downloadsDir, { recursive: true });
    console.log('📁 Created downloads directory');
}

const modulesReady = initializeModules();

app.listen(PORT, () => {
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🚀 Mock Backend Server Started!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`\n📍 Server: http://localhost:${PORT}`);
    console.log(`📦 Valid modules: ${modules.filter(m => m.checksum).length}/${modules.length}`);
    
    if (!modulesReady) {
        console.log('\n⚠️  WARNING: Module files missing!');
        console.log('📝 Run this command:');
        console.log('   node create-test-modules.js');
    }
    
    console.log('\n📚 API Endpoints:');
    console.log(`   GET  http://localhost:${PORT}/api/modules`);
    console.log(`   GET  http://localhost:${PORT}/api/modules/:id`);
    console.log(`   GET  http://localhost:${PORT}/api/test`);
    console.log(`   GET  http://localhost:${PORT}/health`);
    console.log('\n💡 Press Ctrl+C to stop');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
});