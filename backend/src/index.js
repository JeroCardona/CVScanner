const app = require('./app');
const { connect } = require('./database');

async function main() {
    // Database connection
    await connect();

    // Express application
    await app.listen(4000, '0.0.0.0');
    console.log('Server on port 4000: Connected');
    
}

main();
