const app = require('./app');
const { connect } = require('./database');

async function main() {
  // Conexión a la base de datos
  await connect();

  // Inicialización del servidor Express
  await app.listen(4000, '0.0.0.0');
  console.log('Server on port 4000: Connected');
}

main();
