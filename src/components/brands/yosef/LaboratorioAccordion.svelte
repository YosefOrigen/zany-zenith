<script lang="ts">
  type Group = {
    title: string;
    entries: { title: string; anchor: string }[];
  };

  export let groups: Group[] = [];
  let openGroup = 0;
  let isSidebarOpen = false;

  function toggleGroup(index: number) {
    openGroup = openGroup === index ? -1 : index;
  }
</script>

<aside class="lab-sidebar">
  <div class="lab-sidebar-layout">
    <div id="lab-sidebar-content" class="lab-sidebar-content" data-open={isSidebarOpen}>
      <div class="lab-sidebar-control">
        <button
          class="lab-mobile-accordion-trigger"
          type="button"
          aria-controls="lab-sidebar-content"
          aria-expanded={isSidebarOpen}
          aria-label={isSidebarOpen ? 'Cerrar contenido' : 'Abrir contenido'}
          onclick={() => isSidebarOpen = !isSidebarOpen}
        >
          <span class="lab-arrow-icon" aria-hidden="true">→</span>
        </button>
      </div>

      <div class="lab-sidebar-heading">
        <span class="lab-sidebar-meta">Navegación</span>
        <h2>Contenido</h2>
      </div>

      <nav class="lab-accordion" aria-label="Contenido del laboratorio">
        {#each groups as group, index}
          {@const panelId = `lab-group-${index}`}
          {@const isOpen = openGroup === index}
          <div class="lab-accordion-section">
            <button
              class="lab-accordion-toggle"
              type="button"
              aria-controls={panelId}
              aria-expanded={isOpen}
              onclick={() => toggleGroup(index)}
            >
              {group.title}
              <span class="lab-accordion-icon" aria-hidden="true">⌄</span>
            </button>
            <ul id={panelId} class="lab-accordion-content" data-open={isOpen}>
              {#each group.entries as entry}
                <li><a href={`#${entry.anchor}`}>{entry.title}</a></li>
              {/each}
            </ul>
          </div>
        {/each}
      </nav>
    </div>
  </div>
</aside>
