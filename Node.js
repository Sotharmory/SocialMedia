const mongoose = require('mongoose');

mongoose.connect('mongodb://localhost:27017/DouneMDB', {
    useNewUrlParser: true,
    useUnifiedTopology: true
});