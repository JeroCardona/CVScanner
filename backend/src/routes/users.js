const { Router } = require('express');
const router = Router();

const User = require('../models/User');
const { faker } = require('@faker-js/faker');

router.get('/api/users', async(req, res) => {
    const users = await User.find();
    res.json({users});
});

router.get('/api/users/create', async (req, res) => {
    for (let i = 0; i < 5; i++) {  // Corrección en el bucle
        await User.create({
            firstName: faker.name.firstName(),
            lastName: faker.name.lastName(),
            avatar: faker.image.avatar()
        });
    }
    res.json({ message: '5 Users Created' });
});

module.exports = router;