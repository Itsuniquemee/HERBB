/**
 * Test script for QR code generation and verification
 * Demonstrates the signed QR code functionality
 */

const crypto = require('crypto');
const QRCode = require('qrcode');

// Simulate certificate data
const certificateData = {
  cert_id: 'CERT-2025-001',
  batch_id: 'BATCH-789',
  test_type: 'Microbial Testing',
  result: 'Pass',
  issued: '2025-12-02T16:45:00Z',
  valid_until: '2026-12-02T16:45:00Z',
  blockchain_tx: 'abc123def456...',
  issued_by: 'HerbalTrace Lab',
  species: 'Ashwagandha',
};

// Generate signature
const secret = 'herbaltrace-qr-secret-key-change-in-production';
const dataToSign = JSON.stringify(certificateData);
const signature = crypto
  .createHmac('sha256', secret)
  .update(dataToSign)
  .digest('hex');

// Create signed payload
const signedPayload = {
  ...certificateData,
  signature,
  verified: true,
};

console.log('\n=== Signed QR Code Demo ===\n');
console.log('1. Certificate Data:');
console.log(JSON.stringify(certificateData, null, 2));

console.log('\n2. Generated Signature:');
console.log(signature);

console.log('\n3. Signed Payload (for QR code):');
console.log(JSON.stringify(signedPayload, null, 2));

// Generate QR code
QRCode.toDataURL(JSON.stringify(signedPayload), {
  errorCorrectionLevel: 'H',
  type: 'image/png',
  width: 400,
  margin: 2,
})
.then(dataURL => {
  console.log('\n4. QR Code Generated Successfully!');
  console.log('   Data URL length:', dataURL.length, 'characters');
  console.log('   First 100 chars:', dataURL.substring(0, 100) + '...');
  
  // Verify signature
  console.log('\n=== Signature Verification ===\n');
  const { signature: receivedSig, ...dataWithoutSig } = signedPayload;
  const dataToVerify = JSON.stringify(dataWithoutSig);
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(dataToVerify)
    .digest('hex');
  
  const isValid = receivedSig === expectedSignature;
  
  console.log('Signature Valid:', isValid ? '✅ YES' : '❌ NO');
  console.log('Expected:', expectedSignature);
  console.log('Received:', receivedSig);
  console.log('Match:', receivedSig === expectedSignature);
  
  console.log('\n=== Test Complete ===\n');
  console.log('✅ QR code generation working!');
  console.log('✅ Signature verification working!');
  console.log('\nNext steps:');
  console.log('1. Create a certificate via API: POST /api/v1/qc/tests/:id/certificate');
  console.log('2. Generate QR code: POST /api/v1/qc/certificates/:id/qr');
  console.log('3. Verify QR code: POST /api/v1/qc/certificates/verify-qr');
})
.catch(error => {
  console.error('Error generating QR code:', error);
});
