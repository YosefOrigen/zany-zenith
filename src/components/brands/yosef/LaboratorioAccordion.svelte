<script lang="ts">
  type Entry = {
    title: string;
    slug: string;
    parent?: string;
    order: number;
  };

  type Category = {
    slug: string;
    title: string;
    icon: string;
    entries: Entry[];
  };

  let {
    categories = [] as Category[],
    defaultCategory = '' as string
  } = $props();

  let activeCategory = $state('');
  let activeArticle = $state<string | null>(null);
  let expandedCategories = $state(new Set<string>());
  let isSidebarOpen = $state(false);

  function showHome() {
    activeCategory = '';
    activeArticle = null;

    const home = document.querySelector('.lab-home');
    if (home) (home as HTMLElement).style.display = 'grid';

    const layers = document.querySelectorAll('.lab-layer');
    layers.forEach((layer) => {
      (layer as HTMLElement).style.display = 'none';
    });

    document.querySelectorAll('.lab-article-link').forEach((btn) => {
      btn.classList.toggle('active', false);
    });
  }

  function toggleCategory(slug: string) {
    if (expandedCategories.has(slug)) {
      expandedCategories.delete(slug);
    } else {
      expandedCategories.add(slug);
    }
    expandedCategories = new Set(expandedCategories);
    activeCategory = slug;
    activeArticle = null;
    updateLayers(slug);
  }

  function selectArticle(slug: string) {
    activeArticle = slug;
    showOnlyArticle(slug);
  }

  function updateLayers(categorySlug: string) {
    const home = document.querySelector('.lab-home');
    if (home) (home as HTMLElement).style.display = 'none';

    const layers = document.querySelectorAll('.lab-layer');
    layers.forEach((layer) => {
      const el = layer as HTMLElement;
      el.style.display = el.getAttribute('data-layer') === categorySlug ? '' : 'none';
    });

    document.querySelectorAll('.lab-article-link').forEach((btn) => {
      btn.classList.toggle('active', false);
    });
  }

  function showOnlyArticle(slug: string) {
    const home = document.querySelector('.lab-home');
    if (home) (home as HTMLElement).style.display = 'none';

    const layers = document.querySelectorAll('.lab-layer');
    layers.forEach((layer) => {
      const el = layer as HTMLElement;
      el.style.display = el.getAttribute('id') === slug ? '' : 'none';
    });

    document.querySelectorAll('.lab-article-link').forEach((btn) => {
      const btnEl = btn as HTMLElement;
      btnEl.classList.toggle('active', btnEl.getAttribute('data-article') === slug);
    });
  }

  function handleMobileToggle() {
    isSidebarOpen = !isSidebarOpen;
  }
</script>

<aside class="lab-sidebar">
  <div class="lab-sidebar-layout">
    <div id="lab-sidebar-content" class="lab-sidebar-content" data-open={isSidebarOpen}>
      <!-- Mobile control only visible on small screens, stays fixed inside grid row 1 -->
      <div class="lab-sidebar-control">
        <button
          class="lab-mobile-accordion-trigger"
          type="button"
          aria-controls="lab-sidebar-content"
          aria-expanded={isSidebarOpen}
          aria-label={isSidebarOpen ? 'Cerrar contenido' : 'Abrir contenido'}
          onclick={handleMobileToggle}
        >
          <span class="lab-arrow-icon" aria-hidden="true">→</span>
        </button>
      </div>

      <div class="lab-header-group">
        <span class="lab-sidebar-meta">Navegación</span>

        <!-- Home button: estilo "Únete" CTA -->
        <button class="lab-home-button" type="button" onclick={showHome}>
          <h2>Contenido</h2>
        </button>
      </div>

      <!-- Solo el acordeón scrollea en mobile -->
      <div class="lab-accordion-wrapper">
        <nav class="lab-accordion" aria-label="Categorías del laboratorio">
          {#each categories as cat}
            {@const isExpanded = expandedCategories.has(cat.slug)}
            <div class="lab-category-section">
              <button
                class="lab-category-toggle"
                type="button"
                aria-controls={`lab-panel-${cat.slug}`}
                aria-expanded={isExpanded}
                onclick={() => toggleCategory(cat.slug)}
              >
                <span class="lab-category-icon">{cat.icon}</span>
                {cat.title}
                <span class="lab-accordion-icon" aria-hidden="true">⌄</span>
              </button>
              <ul id={`lab-panel-${cat.slug}`} class="lab-category-content" data-open={isExpanded}>
                {#each cat.entries as entry}
                  <li>
                    <button
                      class="lab-article-link"
                      class:active={activeArticle === entry.slug}
                      data-article={entry.slug}
                      onclick={() => selectArticle(entry.slug)}
                    >
                      {#if entry.parent}
                        <span class="lab-sub-indicator">⊢</span>
                      {/if}
                      {entry.title}
                    </button>
                  </li>
                {/each}
              </ul>
            </div>
          {/each}
        </nav>
      </div>
    </div>
  </div>
</aside>

