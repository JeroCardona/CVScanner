const mongoose = require ('mongoose');

async function connect(){
    await mongoose.connect('mongodb://localhost/cvscanner',{
        useUnifiedTopology: true
    });
    console.log('Database:Connected');
};

module.exports = { connect }