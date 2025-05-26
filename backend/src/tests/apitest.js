const APITemplateIO = require('../services/apitemplateio_lib');

async function test() {
    const api = new APITemplateIO('a5d8MjkzNjM6MjY1MzA6eFJCRmdVWDVuTThmSGNTRg=');
    
    try {
        // Test getting account information
        const accountInfo = await api.getAccountInformation();
        console.log('Account Info:', accountInfo);
        
        // Test listing templates
        const templates = await api.listTemplates();
        console.log('Templates:', templates);
        
    } catch (error) {
        console.error('Test failed:', error);
    }
}

test();