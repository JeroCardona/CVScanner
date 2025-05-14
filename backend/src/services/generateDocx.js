// services/generateDocx.js
const fs = require('fs');
const path = require('path');
const PizZip = require('pizzip');
const Docxtemplater = require('docxtemplater');

/**
 * Genera un documento Word (.docx) a partir de una plantilla y datos proporcionados.
 * @param {Object} data - Datos a insertar en la plantilla.
 * @param {string} outputPath - Ruta donde se guardará el documento generado.
 */
function generateResumeDocx(data, outputPath) {
  try {
    const templateName = process.env.DOCX_TEMPLATE || 'resume_template_generated.docx';
    const templatePath = path.resolve(__dirname, '../templates', templateName);
    const content = fs.readFileSync(templatePath, 'binary');

    const zip = new PizZip(content);
    const doc = new Docxtemplater(zip, {
      paragraphLoop: true,
      linebreaks: true,
    });

    doc.setData(data);

    try {
      doc.render();
    } catch (error) {
      console.error('Error al renderizar el documento:', error);
      throw error;
    }

    const outputDir = path.dirname(outputPath);
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    const buf = doc.getZip().generate({ type: 'nodebuffer' });

    fs.writeFileSync(outputPath, buf);
    console.log(`Documento generado exitosamente en: ${outputPath}`);
  } catch (error) {
    console.error('Error al generar el documento:', error);
  }
}

module.exports = generateResumeDocx;