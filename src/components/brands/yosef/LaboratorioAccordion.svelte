<script lang="ts">
  import { onMount } from 'svelte';

  type Entry = {
    title: string;
    slug: string;
    parent?: string;
    order: number;
    subsections?: string[];
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
  let activeSubsection = $state<string | null>(null);
  let expandedCategories = $state(new Set<string>());
  let expandedSubsections = $state(new Set<string>());
  let isSidebarOpen = $state(false);

  onMount(() => {
    if (window.innerWidth > 850) {
      isSidebarOpen = true;
    }
  });

  function showHome() {
    activeCategory = '';
    activeArticle = null;
    activeSubsection = null;

    const home = document.querySelector('.lab-home');
    if (home) (home as HTMLElement).style.display = 'grid';

    const layers = document.querySelectorAll('.lab-layer');
    layers.forEach((layer) => {
      (layer as HTMLElement).style.display = 'none';
    });

    document.querySelectorAll('.lab-article-link').forEach((btn) => {
      btn.classList.toggle('active', false);
    });
    document.querySelectorAll('.lab-subsection-link').forEach((btn) => {
      btn.classList.toggle('active', false);
    });
  }

function showCategory(slug: string) {
    activeCategory = slug;
    activeArticle = null;
    activeSubsection = null;
    updateLayers(slug);
  }

  function toggleCategory(slug: string) {
    if (expandedCategories.has(slug)) {
      expandedCategories.delete(slug);
    } else {
      expandedCategories.add(slug);
    }
    expandedCategories = new Set(expandedCategories);
  }

function selectArticle(slug: string) {
    activeArticle = slug;
    activeSubsection = null;
    // Al abrir un artículo con sub-secciones, las mostramos expandidas por defecto
    expandedSubsections.add(slug);
    expandedSubsections = new Set(expandedSubsections);
    showOnlyArticle(slug);
  }

  function toggleSubsections(slug: string) {
    if (expandedSubsections.has(slug)) {
      expandedSubsections.delete(slug);
    } else {
      expandedSubsections.add(slug);
    }
    expandedSubsections = new Set(expandedSubsections);
  }

  function selectSubsection(entrySlug: string, subsection: string) {
    activeArticle = entrySlug;
    activeSubsection = subsection;
    showOnlyArticle(entrySlug);

    // Esperar a que el contenido esté visible, luego hacer scroll y resaltar
    setTimeout(() => {
      const heading = findHeadingInArticle(entrySlug, subsection);
      if (heading) {
        heading.scrollIntoView({ behavior: 'smooth', block: 'start' });
        heading.classList.remove('lab-subsection-highlight');
        void heading.offsetWidth; // reflow para reiniciar la animación
        heading.classList.add('lab-subsection-highlight');
      }
    }, 80);
  }

  function findHeadingInArticle(articleSlug: string, subsection: string): HTMLElement | null {
    const layer = document.querySelector(`.lab-layer[id="${articleSlug}"]`);
    if (!layer) return null;

    const normalizedTarget = subsection.replace(/[^\p{L}\p{N}\s]/gu, '').trim().toLowerCase();
    const headings = layer.querySelectorAll('h2, h3');
    for (const h of headings) {
      const text = (h as HTMLElement).textContent?.replace(/[^\p{L}\p{N}\s]/gu, '').trim().toLowerCase() || '';
      if (text === normalizedTarget || text.includes(normalizedTarget) || normalizedTarget.includes(text)) {
        return h as HTMLElement;
      }
    }
    return null;
  }

  onMount(() => {
    window.addEventListener('open-category', (e: Event) => {
      const detail = (e as CustomEvent).detail;
      if (detail && detail.slug) {
        showCategory(detail.slug);
      }
    });
  });

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
    document.querySelectorAll('.lab-subsection-link').forEach((btn) => {
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

    document.querySelectorAll('.lab-subsection-link').forEach((btn) => {
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
                  {@const hasSubs = entry.subsections && entry.subsections.length > 0}
                  {@const subsOpen = hasSubs && expandedSubsections.has(entry.slug)}
                  <li>
                    <button
                      class="lab-article-link"
                      class:active={activeArticle === entry.slug}
                      class:has-subs={hasSubs}
                      data-article={entry.slug}
                      aria-expanded={hasSubs ? subsOpen : undefined}
                      onclick={() => selectArticle(entry.slug)}
                    >
                      {#if entry.parent}
                        <span class="lab-sub-indicator">⊢</span>
                      {/if}
                      {entry.title}
                      {#if hasSubs}
                        <span
                          class="lab-article-chevron"
                          class:open={subsOpen}
                          aria-hidden="true"
                          onclick={(e) => { e.stopPropagation(); toggleSubsections(entry.slug); }}
                        >⌄</span>
                      {/if}
                    </button>
                    {#if subsOpen}
                      <ul class="lab-subsection-list">
                        {#each entry.subsections as sub}
                          <li>
                            <button
                              class="lab-subsection-link"
                              class:active={activeSubsection === sub}
                              data-article={entry.slug}
                              data-subsection={sub}
                              onclick={() => selectSubsection(entry.slug, sub)}
                            >
                              <span class="lab-sub-indicator">└</span>
                              {sub}
                            </button>
                          </li>
                        {/each}
                      </ul>
                    {/if}
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

