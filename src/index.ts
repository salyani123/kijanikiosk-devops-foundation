import express from 'express';
import fs from 'fs';
import path from 'path';

const app = express();
const port = 3001;

const packageJsonPath = path.join(__dirname, '../package.json');
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy', version: packageJson.version
    })
});

app.listen(port, '0.0.0.0', () => {
    console.log('kk-payments listening on port', port)
});
