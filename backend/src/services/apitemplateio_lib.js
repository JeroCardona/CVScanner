const fs = require('fs');
const https = require('https');
const http = require('http');
const { URL } = require('url');

class APITemplateIO {
    constructor(apiKey) {
        this.apiKey = apiKey;
    }

    async download(downloadUrl, saveTo) {
        return new Promise((resolve, reject) => {
            const url = new URL(downloadUrl);
            const protocol = url.protocol === 'https:' ? https : http;
            
            const file = fs.createWriteStream(saveTo);
            
            protocol.get(downloadUrl, (response) => {
                response.pipe(file);
                
                file.on('finish', () => {
                    file.close();
                    resolve();
                });
                
                file.on('error', (err) => {
                    fs.unlink(saveTo, () => {}); // Delete the file on error
                    reject(err);
                });
            }).on('error', (err) => {
                reject(err);
            });
        });
    }

    async createPdf(templateId, data, pdfFilePath) {
        return this.create(templateId, data, pdfFilePath, null);
    }

    async createImage(templateId, data, jpegFilePath, pngFilePath) {
        return this.create(templateId, data, jpegFilePath, pngFilePath);
    }

    async create(templateId, data, saveTo1, saveTo2) {
        try {
            const response = await fetch(`https://api.apitemplate.io/v1/create?template_id=${templateId}`, {
                method: 'POST',
                headers: {
                    'X-API-KEY': this.apiKey,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            const respJson = await response.json();
            
            if (respJson.status === 'success') {
                await this.download(respJson.download_url, saveTo1);

                if (respJson.download_url_png && saveTo2 !== null) {
                    await this.download(respJson.download_url_png, saveTo2);
                }

                return true;
            }

            return false;
        } catch (error) {
            console.error('Error in create:', error);
            return false;
        }
    }

    async getAccountInformation() {
        try {
            const response = await fetch('https://api.apitemplate.io/v1/account-information', {
                method: 'GET',
                headers: {
                    'X-API-KEY': this.apiKey
                }
            });

            const respJson = await response.json();
            
            if (respJson.status === 'success') {
                return respJson;
            }

            return null;
        } catch (error) {
            console.error('Error getting account information:', error);
            return null;
        }
    }

    async listTemplates() {
        try {
            const response = await fetch('https://api.apitemplate.io/v1/list-templates', {
                method: 'GET',
                headers: {
                    'X-API-KEY': this.apiKey
                }
            });

            const respJson = await response.json();
            console.log(respJson); // Equivalent to Python's print(response.content)
            
            return respJson;
        } catch (error) {
            console.error('Error listing templates:', error);
            return null;
        }
    }
}

module.exports = APITemplateIO;