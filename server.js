const express = require('express');
const axios = require('axios');
const path = require('path');

const app = express();
const PORT = 4000;

app.use(express.static('public'));
app.use(express.json());

app.get('/weather/:city', async (req, res) => {
  try {
    const city = req.params.city;
    const response = await axios.get(`https://wttr.in/${city}?format=j1`);
    const data = response.data;
    res.json({
      city: city,
      temperature: Math.round(data.current_condition[0].temp_C),
      description: data.current_condition[0].weatherDesc[0].value,
      humidity: data.current_condition[0].humidity
    });
  } catch (error) {
    res.status(404).json({ error: 'City not found or API error' });
  }
});

app.listen(PORT, () => {
  console.log(`Weather app running on http://localhost:${PORT}`);
});