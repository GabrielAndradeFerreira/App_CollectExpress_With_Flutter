{{flutter_js}}
{{flutter_build_config}}

// Sem serviceWorkerSettings o Flutter nao registra service worker, entao o
// navegador nao guarda copia dos arquivos da aplicacao. O index.html remove os
// service workers e caches deixados por versoes anteriores.
_flutter.loader.load();
