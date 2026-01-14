const fs = require('fs');
const path = require('path');
const archiver = require('archiver');

// Create downloads directory
const downloadsDir = path.join(__dirname, 'downloads');
if (!fs.existsSync(downloadsDir)) {
    fs.mkdirSync(downloadsDir, { recursive: true });
}

// Create temp directory for module content
const tempDir = path.join(__dirname, 'temp');
if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
}

// Module 1: Payment Module
function createPaymentModule() {
    console.log('📦 Creating Payment Module...');
    
    const moduleDir = path.join(tempDir, 'payment');
    if (!fs.existsSync(moduleDir)) {
        fs.mkdirSync(moduleDir, { recursive: true });
    }
    
    // Create module.json
    const moduleInfo = {
        id: "feature-payment",
        name: "Payment Module",
        version: "1.0.0",
        description: "Payment processing feature module",
        features: [
            "Credit card processing",
            "PayPal integration",
            "Apple Pay support"
        ],
        createdAt: new Date().toISOString()
    };
    
    fs.writeFileSync(
        path.join(moduleDir, 'module.json'),
        JSON.stringify(moduleInfo, null, 2)
    );
    
    // Create config.json
    const config = {
        apiEndpoint: "https://api.payment.example.com",
        timeout: 30,
        retryCount: 3,
        supportedMethods: ["card", "paypal", "applepay"]
    };
    
    fs.writeFileSync(
        path.join(moduleDir, 'config.json'),
        JSON.stringify(config, null, 2)
    );
    
    // Create README.txt
    const readme = `Payment Module v1.0.0
====================

This module provides payment processing capabilities.

Features:
- Credit card processing
- PayPal integration
- Apple Pay support

Configuration:
See config.json for API settings.

Usage:
1. Load the module
2. Initialize with API key
3. Process payments
`;
    
    fs.writeFileSync(path.join(moduleDir, 'README.txt'), readme);
    
    // Create assets directory
    const assetsDir = path.join(moduleDir, 'assets');
    if (!fs.existsSync(assetsDir)) {
        fs.mkdirSync(assetsDir, { recursive: true });
    }
    
    // Create dummy image file
    fs.writeFileSync(
        path.join(assetsDir, 'icon.txt'),
        'Payment Icon Placeholder'
    );
    
    return zipModule(moduleDir, 'module-payment-v1.0.0.zip');
}

// Module 2: Profile Module
function createProfileModule() {
    console.log('📦 Creating Profile Module...');
    
    const moduleDir = path.join(tempDir, 'profile');
    if (!fs.existsSync(moduleDir)) {
        fs.mkdirSync(moduleDir, { recursive: true });
    }
    
    // Create module.json
    const moduleInfo = {
        id: "feature-profile",
        name: "Profile Module",
        version: "1.1.0",
        description: "User profile management feature module",
        features: [
            "Profile editing",
            "Avatar upload",
            "Settings management"
        ],
        createdAt: new Date().toISOString()
    };
    
    fs.writeFileSync(
        path.join(moduleDir, 'module.json'),
        JSON.stringify(moduleInfo, null, 2)
    );
    
    // Create config.json
    const config = {
        apiEndpoint: "https://api.profile.example.com",
        timeout: 30,
        maxAvatarSize: 5242880, // 5MB
        allowedFormats: ["jpg", "png", "heic"]
    };
    
    fs.writeFileSync(
        path.join(moduleDir, 'config.json'),
        JSON.stringify(config, null, 2)
    );
    
    // Create README.txt
    const readme = `Profile Module v1.1.0
====================

This module provides user profile management.

Features:
- Profile editing
- Avatar upload
- Settings management

What's new in v1.1.0:
- Added HEIC format support
- Improved upload speed
- Bug fixes

Configuration:
See config.json for API settings.
`;
    
    fs.writeFileSync(path.join(moduleDir, 'README.txt'), readme);
    
    // Create assets directory
    const assetsDir = path.join(moduleDir, 'assets');
    if (!fs.existsSync(assetsDir)) {
        fs.mkdirSync(assetsDir, { recursive: true });
    }
    
    // Create dummy files
    fs.writeFileSync(
        path.join(assetsDir, 'default-avatar.txt'),
        'Default Avatar Placeholder'
    );
    
    fs.writeFileSync(
        path.join(assetsDir, 'styles.json'),
        JSON.stringify({ theme: "light", fontSize: 14 }, null, 2)
    );
    
    return zipModule(moduleDir, 'module-profile-v1.1.0.zip');
}

// Zip a module directory
function zipModule(sourceDir, outputFileName) {
    return new Promise((resolve, reject) => {
        const outputPath = path.join(downloadsDir, outputFileName);
        const output = fs.createWriteStream(outputPath);
        const archive = archiver('zip', { zlib: { level: 9 } });
        
        output.on('close', () => {
            const sizeKB = (archive.pointer() / 1024).toFixed(2);
            console.log(`✅ ${outputFileName} created (${sizeKB} KB)`);
            resolve(outputPath);
        });
        
        archive.on('error', (err) => {
            reject(err);
        });
        
        archive.pipe(output);
        archive.directory(sourceDir, false);
        archive.finalize();
    });
}

// Main execution
async function main() {
    try {
        console.log('🚀 Creating test modules...\n');
        
        await createPaymentModule();
        await createProfileModule();
        
        console.log('\n✅ All test modules created successfully!');
        console.log(`📁 Location: ${downloadsDir}`);
        
        // Cleanup temp directory
        fs.rmSync(tempDir, { recursive: true, force: true });
        console.log('🧹 Cleaned up temp files');
        
    } catch (error) {
        console.error('❌ Error creating modules:', error);
        process.exit(1);
    }
}

main();