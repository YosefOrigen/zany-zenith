# Plan de Implementación: Sistema de Capas (Layers) para Laboratorio

## ✅ Paso 1: Actualizar `content.config.ts`
- [x] Schema actualizado: `group` → `category`, agregar `parent` opcional, quitar `anchor`

## ✅ Paso 2: Reorganizar archivos Markdown
- [x] Carpetas creadas: `por-donde-empezar/`, `cursos/`, `herramientas/`, `conceptos/`, `faq/`
- [x] Archivos existentes eliminados (desarrollo/, introduccion/)
- [x] Nuevos artículos creados con frontmatter actualizado

## ✅ Paso 3: Actualizar `LaboratorioAccordion.svelte`
- [x] Recibir `categories` con slugs, títulos, iconos y entradas
- [x] Manejar estado `activeCategory` y `expandedCategories` con Svelte 5 runes
- [x] Al hacer clic en categoría: expandir acordeón + cambiar capa activa
- [x] Al hacer clic en artículo: mostrar solo ese artículo
- [x] Botones de artículo con estado `active`

## ✅ Paso 4: Actualizar `LaboratorioContent.astro`
- [x] Agrupar entries por `category`
- [x] Renderizar cada categoría como `<article>` con `data-layer` y `data-article-slug`
- [x] Pasar estructura de categorías al acordeón
- [x] Slugs sanitizados (sin `/`)

## ✅ Paso 5: Actualizar `index.astro`
- [x] Eliminado `<nav class="lab-subnav">`

## ✅ Paso 6: Actualizar CSS
- [x] Eliminados estilos de `.lab-subnav`
- [x] Agregados estilos para: `.lab-category-toggle`, `.lab-category-content`, `.lab-article-link`, `.lab-description`, tablas
- [x] Ajustado espaciado general

## ✅ Paso 7: Build exitoso
- [x] `astro build` completado sin errores (10 páginas generadas)
- [x] Página `/yosef/laboratorio/index.html` generada correctamente

