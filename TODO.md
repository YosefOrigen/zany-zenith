# TODO: Deep-linking en ContentCards

## Pasos
- [x] Explorar archivos relevantes (ContentCards, config, LaboratorioContent, LaboratorioAccordion)
- [x] Confirmar formato del campo `link` (página / #seccion / #seccion::subseccion)
- [x] 1. Agregar campo opcional `link` al schema de `articulos` en `src/content.config.ts`
- [x] 2. Agregar campo `link` al MD de ejemplo `src/content/Inicio/articulos/laboratorio.md`
- [x] 3. Envolver las tarjetas en `<a>` en `ContentCards.astro`
- [x] 4. Agregar deep-linking en `LaboratorioAccordion.svelte`
- [x] 5. Ajustar CSS `.card` para comportamiento de enlace
- [x] 6. Probar el build/dev server (build ✓ sin errores)
