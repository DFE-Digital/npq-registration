import SwaggerUIBundle from 'swagger-ui-dist/swagger-ui-bundle'

const version = document.getElementById('swagger-ui').dataset.version

document.addEventListener('DOMContentLoaded', () => {
  SwaggerUIBundle({
    url: `/api/docs/${version}/swagger.yaml`,
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
    plugins: [SwaggerUIBundle.plugins.DownloadUrl],
  });
});
