<script lang="ts">
  import { onMount } from 'svelte';

  type Entry = {
    title: string;
    slug: string;
    parent?: string;
    order: number;
    subsections?: string[];
    children?: Entry[];
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

  function ensureParentEntriesExpanded() {
    categories.forEach((cat) => {
      cat.entries.forEach((entry) => {
        if (entry.children && entry.children.length > 0) {
          expandedSubsections.add(entry.slug);
        }
      });
    });
    expandedSubsections = new Set(expandedSubsections);
  }

  onMount(() => {
    if (window.innerWidth > 850) {
      isSidebarOpen = true;
    }
    ensureParentEntriesExpanded();
  });

  function syncArticleNav() {
    document.querySelectorAll('.lab-article-nav').forEach((nav) => {
      const navEl = nav as HTMLElement;
      const targetSlug = navEl.getAttribute('data-nav-for');
      const shouldShow = activeArticle === targetSlug;
      navEl.style.display = shouldShow ? 'flex' : 'none';
    });
  }

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

    syncArticleNav();

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

    const cat = categories.find((c) => c.slug === slug);
    if (cat) {
      cat.entries.forEach((entry) => {
        if (entry.children && entry.children.length > 0) {
          if (expandedCategories.has(slug)) {
            expandedSubsections.add(entry.slug);
          } else {
            expandedSubsections.delete(entry.slug);
          }
        }
      });
      expandedSubsections = new Set(expandedSubsections);
    }
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
      const headings = layer.querySelectorAll('h1, h2, h3');
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

    // Deep-linking: soporte para #seccion y #seccion::subseccion
    function normalize(str: string) {
      return str.replace(/[\s\u00A0]+/g, ' ').replace(/[^\p{L}\p{N}\s]/gu, '').trim().toLowerCase();
    }

    function matchSubsectionName(articleSlug: string, headingEl: HTMLElement) {
      const cat = categories.find((c) => c.entries.some((e) => e.slug === articleSlug));
      if (!cat) return null;
      const entry = cat.entries.find((e) => e.slug === articleSlug);
      if (!entry || !entry.subsections) return null;
      const headingText = (headingEl.textContent || '').trim();
      const normalizedHeading = normalize(headingText);
      for (const sub of entry.subsections) {
        const n = normalize(sub);
        if (n === normalizedHeading || n.includes(normalizedHeading) || normalizedHeading.includes(n)) {
          return sub;
        }
      }
      return null;
    }

    // Maneja hashes tipo '#slug::subsection' o '#elementId'
    function processHash() {
      const hash = window.location.hash;
      if (!hash || hash === '#') {
        showHome();
        return;
      }
      const raw = decodeURIComponent(hash.slice(1));

      if (raw.includes('::')) {
        const parts = raw.split('::');
        const slug = parts[0];
        const subsection = parts[1] || null;
        if (!slug) return;

        const cat = categories.find((c) => c.entries.some((e) => e.slug === slug));
        if (cat) {
          expandedCategories.add(cat.slug);
          expandedCategories = new Set(expandedCategories);
        }

        const layer = document.querySelector(`.lab-layer[id="${CSS.escape(slug)}"]`) as HTMLElement | null;
        if (!layer) return;

        const catData = layer.getAttribute('data-layer');
        if (catData) activeCategory = catData;
        activeArticle = slug;
        activeSubsection = subsection;
        expandedSubsections.add(slug);
        expandedSubsections = new Set(expandedSubsections);
        showOnlyArticle(slug);

        setTimeout(() => {
          if (subsection) {
            const heading = findHeadingInArticle(slug, subsection);
            if (heading) {
              heading.scrollIntoView({ behavior: 'smooth', block: 'start' });
              heading.classList.remove('lab-subsection-highlight');
              void heading.offsetWidth;
              heading.classList.add('lab-subsection-highlight');
            }
          } else {
            const el = document.querySelector(`.lab-layer[id="${CSS.escape(slug)}"]`);
            if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
          }
        }, 80);
        return;
      }

      // Si no es el formato slug::subsection, puede ser un id de elemento (p.ej. MDX)
      const target = document.getElementById(raw);
      if (target) {
        const layer = target.closest('.lab-layer') as HTMLElement | null;
        if (layer) {
          const slug = layer.getAttribute('id') || '';
          const catData = layer.getAttribute('data-layer');
          if (catData) activeCategory = catData;
          activeArticle = slug;
          expandedSubsections.add(slug);
          expandedSubsections = new Set(expandedSubsections);
          showOnlyArticle(slug);

          const matchedSub = matchSubsectionName(slug, target as HTMLElement);
          if (matchedSub) activeSubsection = matchedSub;

          setTimeout(() => {
            (target as HTMLElement).scrollIntoView({ behavior: 'smooth', block: 'start' });
            (target as HTMLElement).classList.remove('lab-subsection-highlight');
            void (target as HTMLElement).offsetWidth;
            (target as HTMLElement).classList.add('lab-subsection-highlight');
          }, 80);
        }
      }
    }

    processHash();
    window.addEventListener('hashchange', processHash);

    // Observador para actualizar el TOC/links al hacer scroll por el contenido
    const io = new IntersectionObserver((entries) => {
      for (const ent of entries) {
        if (!ent.isIntersecting) continue;
        const heading = ent.target as HTMLElement;
        const layer = heading.closest('.lab-layer') as HTMLElement | null;
        if (!layer) continue;
        const slug = layer.getAttribute('id') || '';
        const matched = matchSubsectionName(slug, heading);
        if (matched) {
          activeArticle = slug;
          activeSubsection = matched;
          expandedSubsections.add(slug);
          expandedSubsections = new Set(expandedSubsections);
          showOnlyArticle(slug);
        }
      }
    }, { root: null, rootMargin: '0px 0px -66% 0px', threshold: 0 });

    function observeHeadings() {
      const headings = document.querySelectorAll('.lab-layer h1[id], .lab-layer h2[id], .lab-layer h3[id]');
      headings.forEach((h) => io.observe(h));
    }

    // Clicks en enlaces de ancla dentro del contenido (MD/MDX)
    function onDocumentClick(e: Event) {
      const el = e.target as HTMLElement;
      const a = el.closest && el.closest('a');
      if (!a) return;
      const href = (a as HTMLAnchorElement).getAttribute('href') || '';
      if (!href.startsWith('#')) return;
      // Dejar que el navegador cambie el hash y luego processHash() se ejecutará por hashchange
    }

    // Iniciar observador y listeners
    observeHeadings();
    document.addEventListener('click', onDocumentClick);

    // Cleanup al desmontar
    return () => {
      window.removeEventListener('hashchange', processHash);
      document.removeEventListener('click', onDocumentClick);
      io.disconnect();
    };
  });

  function updateLayers(categorySlug: string) {
    const home = document.querySelector('.lab-home');
    if (home) (home as HTMLElement).style.display = 'none';

    const layers = document.querySelectorAll('.lab-layer');
    layers.forEach((layer) => {
      const el = layer as HTMLElement;
      el.style.display = el.getAttribute('data-layer') === categorySlug ? '' : 'none';
    });

    document.querySelectorAll('.lab-article-nav').forEach((nav) => {
      (nav as HTMLElement).style.display = 'none';
    });

    // Limpiar estados activos al cambiar de categoría
    document.querySelectorAll('.lab-article-link').forEach((btn) => {
      (btn as HTMLElement).classList.toggle('active', false);
    });
    document.querySelectorAll('.lab-subsection-link').forEach((btn) => {
      (btn as HTMLElement).classList.toggle('active', false);
    });
    activeArticle = null;
    activeSubsection = null;
  }

  function showOnlyArticle(slug: string) {
    const home = document.querySelector('.lab-home');
    if (home) (home as HTMLElement).style.display = 'none';

    const layers = document.querySelectorAll('.lab-layer');
    layers.forEach((layer) => {
      const el = layer as HTMLElement;
      el.style.display = el.getAttribute('id') === slug ? '' : 'none';
    });

    document.querySelectorAll('.lab-article-nav').forEach((nav) => {
      const navEl = nav as HTMLElement;
      navEl.style.display = navEl.getAttribute('data-nav-for') === slug ? 'flex' : 'none';
    });

    document.querySelectorAll('.lab-article-link').forEach((btn) => {
      const btnEl = btn as HTMLElement;
      btnEl.classList.toggle('active', btnEl.getAttribute('data-article') === slug);
    });

    // Solo marcar como active la subsección que coincida con `activeSubsection`
    document.querySelectorAll('.lab-subsection-link').forEach((btn) => {
      const btnEl = btn as HTMLElement;
      const btnArticle = btnEl.getAttribute('data-article');
      const btnSub = btnEl.getAttribute('data-subsection');
      const isActive = btnArticle === slug && activeSubsection === btnSub;
      btnEl.classList.toggle('active', !!isActive);
    });

    // Si no hay subsección activa, hacer scroll al primer heading del artículo
    if (!activeSubsection) {
      setTimeout(() => {
        const layerEl = document.querySelector(`.lab-layer[id="${CSS.escape(slug)}"]`) as HTMLElement | null;
        if (!layerEl) return;
        const firstHeading = layerEl.querySelector('h1, h2, h3') as HTMLElement | null;
        if (firstHeading) {
          firstHeading.scrollIntoView({ behavior: 'smooth', block: 'start' });
        } else {
          layerEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      }, 60);
    }
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
                  {@const hasSubs = Boolean(entry.children?.length) || (entry.subsections && entry.subsections.length > 0)}
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
                        {#if entry.children && entry.children.length > 0}
                          {#each entry.children as child}
                            <li>
                              <button
                                class="lab-subsection-link"
                                class:active={activeArticle === child.slug}
                                data-article={child.slug}
                                data-subsection={child.title}
                                onclick={() => selectArticle(child.slug)}
                              >
                                <span class="lab-sub-indicator">└</span>
                                {child.title}
                              </button>

                              {#if child.children && child.children.length > 0}
                                <ul class="lab-subsection-list lab-subsection-list--nested">
                                  {#each child.children as grandchild}
                                    <li>
                                      <button
                                        class="lab-subsection-link"
                                        class:active={activeArticle === grandchild.slug}
                                        data-article={grandchild.slug}
                                        data-subsection={grandchild.title}
                                        onclick={() => selectArticle(grandchild.slug)}
                                      >
                                        <span class="lab-sub-indicator">└</span>
                                        {grandchild.title}
                                      </button>
                                    </li>
                                  {/each}
                                </ul>
                              {/if}
                            </li>
                          {/each}
                        {/if}

                        {#if entry.subsections && entry.subsections.length > 0}
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
                        {/if}
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

