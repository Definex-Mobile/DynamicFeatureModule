const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('🔐 RSA Key Pair Generation');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// Generate RSA key pair
console.log('⏳ Generating 2048-bit RSA key pair...');

const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: {
        type: 'spki',
        format: 'pem'
    },
    privateKeyEncoding: {
        type: 'pkcs8',
        format: 'pem'
    }
});

// Create keys directory
const keysDir = path.join(__dirname, '..', 'keys');
if (!fs.existsSync(keysDir)) {
    fs.mkdirSync(keysDir, { recursive: true });
}

// Save private key
const privateKeyPath = path.join(keysDir, 'private.pem');
fs.writeFileSync(privateKeyPath, privateKey);
console.log(`✅ Private key saved: ${privateKeyPath}`);

// Save public key
const publicKeyPath = path.join(keysDir, 'public.pem');
fs.writeFileSync(publicKeyPath, publicKey);
console.log(`✅ Public key saved: ${publicKeyPath}`);

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('📋 Public Key (copy to SecurityConfiguration.swift):');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log(publicKey);
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

console.log('⚠️  IMPORTANT:');
console.log('1. Copy the public key above');
console.log('2. Paste it in SecurityConfiguration.swift');
console.log('3. Replace the manifestPublicKey constant');
console.log('4. Keep private.pem SECRET and secure!');
console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');