const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const archiver = require('archiver');

const app = express();
const PORT = 8000;

// Middleware
app.use(cors());
app.use(express.json());

// Load RSA private key
let privateKey;
try {
    privateKey = fs.readFileSync(path.join(__dirname, 'keys', 'private.pem'), 'utf8');
    console.log('✅ Private key loaded');
} catch (error) {
    console.error('❌ Failed to load private key. Run: npm run generate-keys');
    process.exit(1);
}

// Configuration
const ENVIRONMENT = process.env.NODE_ENV || 'development';

// MARK: - Signature Generation

function generateSignature(data) {
    const sign = crypto.createSign('RSA-SHA256');
    sign.update(JSON.stringify(data));
    sign.end();
    
    const signature = sign.sign(privateKey);
    return signature.toString('base64');
}

function generateChecksum(filePath) {
    const fileBuffer = fs.readFileSync(filePath);
    const hash = crypto.createHash('sha256');
    hash.update(fileBuffer);
    return hash.digest('hex');
}

function generateNonce() {
    return crypto.randomBytes(16).toString('hex');
}

// MARK: - Module Database (In-memory)

const availableModules = [
    {
        id: 'feature-dashboard',
        name: 'Dashboard Module',
        version: '1.0.0',
        environment: ENVIRONMENT,
        description: 'Interactive dashboard with charts',
        author: 'Dynamic Team'
    },
    {
        id: 'feature-settings',
        name: 'Settings Module',
        version: '1.2.3',
        environment: ENVIRONMENT,
        description: 'Advanced settings panel',
        author: 'Dynamic Team'
    }
];

// MARK: - API Endpoints

// Health check
app.get('/api/test', (req, res) => {
    res.json({
        status: 'ok',
        message: 'Backend is working!',
        timestamp: new Date().toISOString(),
        environment: ENVIRONMENT,
        availableModules: availableModules.length,
        security: {
            signatureAlgorithm: 'RSA-SHA256',
            checksumAlgorithm: 'SHA-256',
            timestampFormat: 'ISO8601'
        }
    });
});

// Get modules with signed manifest
app.get('/api/modules', async (req, res) => {
    try {
        console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('📋 Client requesting module list');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        // Ensure modules directory exists
        const modulesDir = path.join(__dirname, 'modules');
        if (!fs.existsSync(modulesDir)) {
            fs.mkdirSync(modulesDir, { recursive: true });
        }
        
        // Generate ZIP files for modules (if not exist)
        const modulesWithMetadata = await Promise.all(
            availableModules.map(async (module) => {
                const zipPath = path.join(modulesDir, `${module.id}.zip`);
                
                // Generate ZIP if doesn't exist
                if (!fs.existsSync(zipPath)) {
                    console.log(`📦 Generating ${module.id}.zip...`);
                    await generateModuleZip(module.id, zipPath);
                }
                
                // Calculate checksum and size
                const checksum = generateChecksum(zipPath);
                const stats = fs.statSync(zipPath);
                
                return {
                    id: module.id,
                    name: module.name,
                    version: module.version,
                    checksum: checksum,
                    size: stats.size,
                    environment: module.environment
                };
            })
        );
        
        // Create manifest data
        const timestamp = new Date().toISOString();
        const nonce = generateNonce();
        
        const manifestData = {
            modules: modulesWithMetadata,
            timestamp: timestamp,
            nonce: nonce,
            environment: ENVIRONMENT
        };
        
        console.log('📝 Manifest data:', manifestData);
        
        // Generate signature
        console.log('🔐 Generating RSA signature...');
        const signature = generateSignature(manifestData);
        
        console.log('✅ Signature generated:', signature.substring(0, 32) + '...');
        
        // Signed manifest
        const signedManifest = {
            manifest: {
                ...manifestData,
                signature: signature
            },
            server_time: timestamp
        };
        
        console.log('✅ Sending signed manifest');
        console.log(`   Modules: ${modulesWithMetadata.length}`);
        console.log(`   Timestamp: ${timestamp}`);
        console.log(`   Nonce: ${nonce.substring(0, 16)}...`);
        console.log(`   Signature: ${signature.substring(0, 16)}...`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        res.json(signedManifest);
        
    } catch (error) {
        console.error('❌ Error generating manifest:', error);
        res.status(500).json({
            error: 'Failed to generate manifest',
            message: error.message
        });
    }
});

// Download module
app.get('/api/modules/:moduleId/download', (req, res) => {
    const { moduleId } = req.params;
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`📥 Download request: ${moduleId}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    const zipPath = path.join(__dirname, 'modules', `${moduleId}.zip`);
    
    if (!fs.existsSync(zipPath)) {
        console.log(`❌ Module not found: ${moduleId}`);
        return res.status(404).json({
            error: 'Module not found',
            moduleId: moduleId
        });
    }
    
    const stats = fs.statSync(zipPath);
    console.log(`✅ Sending ${moduleId}.zip (${stats.size} bytes)`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    res.download(zipPath, `${moduleId}.zip`);
});

// MARK: - Module ZIP Generation

async function generateModuleZip(moduleId, outputPath) {
    return new Promise((resolve, reject) => {
        const output = fs.createWriteStream(outputPath);
        const archive = archiver('zip', {
            zlib: { level: 9 } // Maximum compression
        });
        
        output.on('close', () => {
            console.log(`✅ ${moduleId}.zip created (${archive.pointer()} bytes)`);
            resolve();
        });
        
        archive.on('error', (err) => {
            reject(err);
        });
        
        archive.pipe(output);
        
        // Generate HTML content
        const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${moduleId}</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>🎉 ${moduleId}</h1>
        <p>This module was dynamically loaded!</p>
        <div class="info">
            <strong>Module ID:</strong> ${moduleId}<br>
            <strong>Version:</strong> 1.0.0<br>
            <strong>Status:</strong> ✅ Loaded Successfully
        </div>
        <button onclick="alert('Module is working!')">Test Button</button>
    </div>
    <script src="script.js"></script>
</body>
</html>`;
        
        // Generate CSS
        const cssContent = `
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #333;
}

.container {
    background: white;
    padding: 3rem;
    border-radius: 20px;
    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
    text-align: center;
    max-width: 500px;
}

h1 {
    color: #667eea;
    margin-bottom: 1rem;
    font-size: 2.5rem;
}

p {
    font-size: 1.2rem;
    color: #666;
    margin-bottom: 2rem;
}

.info {
    background: #f8f9fa;
    padding: 1.5rem;
    border-radius: 10px;
    margin-bottom: 2rem;
    text-align: left;
    line-height: 1.8;
}

button {
    background: #667eea;
    color: white;
    border: none;
    padding: 1rem 2rem;
    font-size: 1.1rem;
    border-radius: 10px;
    cursor: pointer;
    transition: all 0.3s ease;
}

button:hover {
    background: #764ba2;
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0,0,0,0.2);
}`;
        
        // Generate JavaScript
        const jsContent = `
console.log('✅ ${moduleId} loaded successfully!');

document.addEventListener('DOMContentLoaded', () => {
    console.log('📦 Module: ${moduleId}');
    console.log('🔒 Loaded via secure dynamic loading');
});

window.moduleAPI = {
    name: '${moduleId}',
    version: '1.0.0',
    initialize: function() {
        console.log('Initializing ${moduleId}...');
    }
};
`;
        
        // Add files to archive
        archive.append(htmlContent, { name: 'index.html' });
        archive.append(cssContent, { name: 'style.css' });
        archive.append(jsContent, { name: 'script.js' });
        
        // Add a metadata file
        const metadata = {
            id: moduleId,
            version: '1.0.0',
            generated: new Date().toISOString(),
            files: ['index.html', 'style.css', 'script.js']
        };
        archive.append(JSON.stringify(metadata, null, 2), { name: 'manifest.json' });
        
        archive.finalize();
    });
}

// Start server
app.listen(PORT, () => {
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🚀 Dynamic Module Backend Server');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Server running at: http://localhost:${PORT}`);
    console.log(`🔒 Environment: ${ENVIRONMENT}`);
    console.log(`🔐 Security: RSA-2048 + SHA-256`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('\nEndpoints:');
    console.log(`  GET  /api/test`);
    console.log(`  GET  /api/modules`);
    console.log(`  GET  /api/modules/:id/download`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
});