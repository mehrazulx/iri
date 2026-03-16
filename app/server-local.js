const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>Hello World App</title></head>
      <body>
        <h1>Hello, World!</h1>
        <p>This is a simple Node.js application deployed on AWS ECS with Fargate!</p>
        <p>Deployment automated with Terraform and GitHub Actions</p>
      </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on port ${port}`);
});
