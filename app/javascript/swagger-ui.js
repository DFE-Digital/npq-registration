import SwaggerUI from 'swagger-ui'

const version = document.getElementById('swagger-ui').dataset.version

document.addEventListener('DOMContentLoaded', () => {
  SwaggerUI({
    url: `/api/docs/${version}/swagger.yaml`,
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [SwaggerUI.presets.apis],
    plugins: [SwaggerUI.plugins.DownloadUrl],
  });
});
