const fetch = require('node-fetch');

async function testAPI() {
  const baseUrl = 'http://localhost:3000';
  
  console.log('Testing API endpoints...');
  
  // Test OPTIONS request (CORS preflight)
  try {
    const optionsResponse = await fetch(`${baseUrl}/api/report`, {
      method: 'OPTIONS',
      headers: {
        'Origin': 'http://localhost:3000',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type, Authorization'
      }
    });
    
    console.log('OPTIONS /api/report status:', optionsResponse.status);
    console.log('CORS headers:', {
      'Access-Control-Allow-Origin': optionsResponse.headers.get('Access-Control-Allow-Origin'),
      'Access-Control-Allow-Methods': optionsResponse.headers.get('Access-Control-Allow-Methods'),
      'Access-Control-Allow-Headers': optionsResponse.headers.get('Access-Control-Allow-Headers')
    });
  } catch (error) {
    console.error('OPTIONS test failed:', error.message);
  }
  
  // Test POST request without auth (should return 401)
  try {
    const postResponse = await fetch(`${baseUrl}/api/report`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'http://localhost:3000'
      },
      body: JSON.stringify({
        category: 'test',
        location: 'test',
        description: 'test',
        public_key: 'test'
      })
    });
    
    console.log('POST /api/report status:', postResponse.status);
    const responseText = await postResponse.text();
    console.log('Response:', responseText);
  } catch (error) {
    console.error('POST test failed:', error.message);
  }
}

testAPI().catch(console.error);
