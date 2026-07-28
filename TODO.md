# Sidebar Fijo Colapsable - Plan de Implementación

## Pasos

- [x] 1. Leer y entender archivos relevantes
- [x] 2. Plan aprobado por el usuario
- [x] 3. Editar `src/styles/yosef/yosef-laboratorio.css`
  - [x] 3a. `.lab-layout`: grid 1 columna + `padding-left` dinámico con `:has()`
  - [x] 3b. `.lab-sidebar` desktop: `position: fixed; left: 0; top: 100px; height: calc(100vh - 100px)`
  - [x] 3c. `.lab-sidebar-content` desktop: estructura colapsable (grid, transiciones width/opacity)
  - [x] 3d. Mostrar `.lab-mobile-accordion-trigger` también en desktop
  - [x] 3e. Mobile: reset `padding-left: 0` y `margin: 0` en sidebar-content
- [x] 4. Editar `src/components/brands/yosef/LaboratorioAccordion.svelte`
  - [x] 4a. Import `onMount`
  - [x] 4b. En `onMount`, si `window.innerWidth > 850`, `isSidebarOpen = true`
- [ ] 5. Verificar build

