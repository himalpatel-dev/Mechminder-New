const multer = require('multer');
const path = require('path');
const fs = require('fs');

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        // Express lowercases headers automatically, but we check both just in case
        const type = req.headers['x-parent-type'] || req.headers['X-Parent-Type'] || 'vehicles';
        
        // Ensure the base 'uploads' folder exists first
        const baseDir = path.resolve('uploads');
        if (!fs.existsSync(baseDir)) {
            fs.mkdirSync(baseDir, { recursive: true });
        }

        const targetDir = path.join(baseDir, type);
        console.log(`[Upload] Saving to directory: ${targetDir}`);
        
        if (!fs.existsSync(targetDir)) {
            fs.mkdirSync(targetDir, { recursive: true });
        }
        cb(null, targetDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const name = file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname);
        console.log(`[Upload] Assigned filename: ${name}`);
        cb(null, name);
    }
});

const upload = multer({ storage: storage });

module.exports = upload;
