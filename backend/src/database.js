const mongoose = require('mongoose');

async function connect() {
    try {
        await mongoose.connect('mongodb://localhost:27017/cvscanner');
        console.log('Database: Connected');
    } catch (error) {
        console.error(error);
    }
}

module.exports = { connect };
