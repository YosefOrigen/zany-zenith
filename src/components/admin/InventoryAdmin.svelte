<script lang="ts">
  import { onMount } from 'svelte';
  import type { SupabaseClient, User } from '@supabase/supabase-js';
  import { getSupabaseClient, supabaseReady } from '../../lib/supabase';

  const imageBucket = 'yosef-product-images';

  type Category = { id: string; name: string; slug: string };
  type ProductImage = { id: string; storage_path: string; alt_text: string; position: number };
  type ProductVariant = {
    id: string;
    name: string;
    sku: string | null;
    price: number | null;
    cost: number | null;
    stock: number;
    is_active: boolean;
  };
  type Product = {
    id: string;
    name: string;
    sku: string | null;
    price: number;
    cost: number;
    stock: number;
    description: string;
    category_id: string | null;
    is_active: boolean;
    store_categories: { name: string } | null;
    store_product_images: ProductImage[];
    store_product_variants: ProductVariant[];
  };
  type VariantDraft = {
    id?: string;
    name: string;
    sku: string;
    price: string;
    cost: string;
    stock: string;
    is_active: boolean;
  };
  type View = 'loading' | 'setup' | 'signed-out' | 'denied' | 'catalog';

  let supabase: SupabaseClient | null = null;
  let currentUser: User | null = null;
  let view: View = 'loading';
  let products: Product[] = [];
  let categories: Category[] = [];
  let message = '';
  let messageError = false;
  let loadingProducts = false;
  let saving = false;
  let showForm = false;
  let editingProduct: Product | null = null;
  let existingImages: ProductImage[] = [];
  let selectedPhotos: File[] = [];
  let name = '';
  let sku = '';
  let price = '';
  let cost = '';
  let stock = '0';
  let description = '';
  let categoryName = '';
  let isActive = true;
  let variantDrafts: VariantDraft[] = [];
  let search = '';
  let filter: 'all' | 'active' | 'inactive' = 'all';

  $: visibleProducts = products.filter((product) => {
    const term = search.trim().toLowerCase();
    const matchesSearch = !term ||
      product.name.toLowerCase().includes(term) ||
      (product.sku ?? '').toLowerCase().includes(term) ||
      (product.store_categories?.name ?? '').toLowerCase().includes(term);
    const matchesFilter = filter === 'all' ||
      (filter === 'active' && product.is_active) ||
      (filter === 'inactive' && !product.is_active);
    return matchesSearch && matchesFilter;
  });

  onMount(() => {
    if (!supabaseReady) {
      view = 'setup';
      return;
    }

    supabase = getSupabaseClient();
    if (!supabase) {
      view = 'setup';
      return;
    }

    let active = true;
    const auth = supabase.auth;
    auth.getSession().then(({ data, error }) => {
      if (!active) return;
      if (error) {
        setMessage('No se pudo comprobar la sesión. Recarga la página para intentarlo de nuevo.', true);
        view = 'signed-out';
        return;
      }
      void handleSession(data.session?.user ?? null);
    });

    const { data: listener } = auth.onAuthStateChange((_event, session) => {
      if (active) void handleSession(session?.user ?? null);
    });

    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  });

  async function handleSession(user: User | null) {
    currentUser = user;
    message = '';
    if (!user || !supabase) {
      view = 'signed-out';
      return;
    }

    const { data, error } = await supabase
      .from('store_admins')
      .select('user_id')
      .eq('user_id', user.id)
      .maybeSingle();

    if (error) {
      view = 'denied';
      setMessage('No se pudo verificar tu permiso. Revisa que la migración del catálogo esté aplicada.', true);
      return;
    }
    if (!data) {
      view = 'denied';
      return;
    }

    view = 'catalog';
    await loadCatalog();
  }

  function setMessage(text: string, isError = false) {
    message = text;
    messageError = isError;
  }

  async function signInWithGoogle() {
    if (!supabase) return;
    setMessage('Abriendo el inicio de sesión de Google…');
    sessionStorage.setItem('yosef-admin-login', 'true');
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: `${window.location.origin}/yosef/cuenta` },
    });
    if (error) {
      sessionStorage.removeItem('yosef-admin-login');
      setMessage('No se pudo iniciar sesión. Revisa que Google esté conectado en Supabase.', true);
    }
  }

  async function signOut() {
    if (!supabase) return;
    await supabase.auth.signOut();
    view = 'signed-out';
    currentUser = null;
  }

  async function loadCatalog() {
    if (!supabase) return;
    loadingProducts = true;
    const [categoryResult, productResult, productCostsResult, variantCostsResult] = await Promise.all([
      supabase.from('store_categories').select('id, name, slug').order('name'),
      supabase
        .from('store_products')
        .select('id, name, sku, price, stock, description, category_id, is_active, store_categories(name), store_product_images(id, storage_path, alt_text, position), store_product_variants(id, name, sku, price, stock, is_active)')
        .order('updated_at', { ascending: false }),
      supabase.from('store_product_costs').select('product_id, cost'),
      supabase.from('store_product_variant_costs').select('variant_id, cost'),
    ]);

    if (categoryResult.error || productResult.error || productCostsResult.error || variantCostsResult.error) {
      setMessage('No se pudo cargar el catálogo. Comprueba que la migración y las políticas RLS estén activas.', true);
    } else {
      categories = categoryResult.data ?? [];
      const productCosts = new Map((productCostsResult.data ?? []).map((item) => [item.product_id, Number(item.cost)]));
      const variantCosts = new Map((variantCostsResult.data ?? []).map((item) => [item.variant_id, Number(item.cost)]));
      products = ((productResult.data ?? []) as Product[]).map((product) => ({
        ...product,
        cost: productCosts.get(product.id) ?? 0,
        store_product_variants: (product.store_product_variants ?? []).map((variant) => ({
          ...variant,
          cost: variantCosts.get(variant.id) ?? null,
        })),
      }));
      message = '';
    }
    loadingProducts = false;
  }

  function imageUrl(path: string) {
    return supabase?.storage.from(imageBucket).getPublicUrl(path).data.publicUrl ?? '';
  }

  function openNewProduct() {
    editingProduct = null;
    existingImages = [];
    selectedPhotos = [];
    name = '';
    sku = '';
    price = '';
    cost = '';
    stock = '0';
    description = '';
    categoryName = '';
    isActive = true;
    variantDrafts = [];
    showForm = true;
    message = '';
  }

  function openEditProduct(product: Product) {
    editingProduct = product;
    existingImages = [...(product.store_product_images ?? [])].sort((a, b) => a.position - b.position);
    selectedPhotos = [];
    name = product.name;
    sku = product.sku ?? '';
    price = String(product.price);
    cost = String(product.cost);
    stock = String(product.stock);
    description = product.description;
    categoryName = product.store_categories?.name ?? '';
    isActive = product.is_active;
    variantDrafts = (product.store_product_variants ?? []).map((variant) => ({
      id: variant.id,
      name: variant.name,
      sku: variant.sku ?? '',
      price: variant.price === null ? '' : String(variant.price),
      cost: variant.cost === null ? '' : String(variant.cost),
      stock: String(variant.stock),
      is_active: variant.is_active,
    }));
    showForm = true;
    message = '';
  }

  function closeForm() {
    showForm = false;
    editingProduct = null;
    selectedPhotos = [];
  }

  function addPhotos(event: Event) {
    const input = event.currentTarget as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    const allowed = files.filter((file) =>
      ['image/jpeg', 'image/png', 'image/webp', 'image/avif'].includes(file.type) && file.size <= 5 * 1024 * 1024,
    );
    if (allowed.length !== files.length) {
      setMessage('Cada foto debe ser JPG, PNG, WebP o AVIF y pesar hasta 5 MB.', true);
    } else {
      message = '';
    }
    selectedPhotos = [...selectedPhotos, ...allowed];
    input.value = '';
  }

  function removeSelectedPhoto(index: number) {
    selectedPhotos = selectedPhotos.filter((_, photoIndex) => photoIndex !== index);
  }

  async function removeExistingImage(image: ProductImage) {
    if (!supabase || !editingProduct) return;
    const { error } = await supabase
      .from('store_product_images')
      .delete()
      .eq('id', image.id)
      .eq('product_id', editingProduct.id);
    if (error) {
      setMessage('No se pudo quitar la foto.', true);
      return;
    }
    await supabase.storage.from(imageBucket).remove([image.storage_path]);
    existingImages = existingImages.filter((item) => item.id !== image.id);
  }

  function addVariant() {
    variantDrafts = [...variantDrafts, { name: '', sku: '', price: '', cost: '', stock: '0', is_active: true }];
  }

  function removeVariant(index: number) {
    variantDrafts = variantDrafts.filter((_, variantIndex) => variantIndex !== index);
  }

  function makeSlug(value: string) {
    return value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
      .trim().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  }

  async function resolveCategory(): Promise<string | null> {
    if (!supabase || !categoryName.trim()) return null;
    const slug = makeSlug(categoryName);
    if (!slug) return null;
    const existing = await supabase.from('store_categories').select('id').eq('slug', slug).maybeSingle();
    if (existing.error) throw existing.error;
    if (existing.data) return existing.data.id;
    const created = await supabase
      .from('store_categories')
      .insert({ name: categoryName.trim(), slug })
      .select('id')
      .single();
    if (created.error) throw created.error;
    return created.data.id;
  }

  async function saveVariants(productId: string, oldVariants: ProductVariant[]) {
    if (!supabase) throw new Error('No hay conexión con Supabase.');
    const validVariants = variantDrafts.filter((variant) => variant.name.trim());
    const payload = validVariants.map((variant) => ({
      id: variant.id ?? crypto.randomUUID(),
      product_id: productId,
      name: variant.name.trim(),
      sku: variant.sku.trim() || null,
      price: variant.price === '' ? null : Number(variant.price),
      stock: Number(variant.stock || 0),
      is_active: variant.is_active,
      updated_at: new Date().toISOString(),
    }));
    const retainedIds = new Set(payload.flatMap((variant) => variant.id ? [variant.id] : []));
    const idsToDelete = oldVariants.map((variant) => variant.id).filter((id) => !retainedIds.has(id));

    if (idsToDelete.length) {
      const { error } = await supabase
        .from('store_product_variants')
        .delete()
        .eq('product_id', productId)
        .in('id', idsToDelete);
      if (error) throw error;
    }
    if (payload.length) {
      const { error } = await supabase.from('store_product_variants').upsert(payload, { onConflict: 'id' });
      if (error) throw error;

      const variantIds = payload.map((variant) => variant.id);
      const removedCosts = await supabase
        .from('store_product_variant_costs')
        .delete()
        .in('variant_id', variantIds);
      if (removedCosts.error) throw removedCosts.error;

      const costs = validVariants.flatMap((variant, index) =>
        variant.cost === '' ? [] : [{ variant_id: payload[index].id, cost: Number(variant.cost) }],
      );
      if (costs.length) {
        const { error: costError } = await supabase
          .from('store_product_variant_costs')
          .insert(costs);
        if (costError) throw costError;
      }
    }
  }

  async function uploadPhotos(productId: string) {
    if (!supabase || !selectedPhotos.length) return;
    const uploadedPaths: string[] = [];
    const rows: { product_id: string; storage_path: string; alt_text: string; position: number }[] = [];
    const startingPosition = existingImages.length;

    for (const [index, photo] of selectedPhotos.entries()) {
      const safeName = photo.name.replace(/[^a-zA-Z0-9._-]/g, '-');
      const path = `${productId}/${crypto.randomUUID()}-${safeName}`;
      const { error } = await supabase.storage.from(imageBucket).upload(path, photo, {
        cacheControl: '3600',
        upsert: false,
        contentType: photo.type,
      });
      if (error) {
        if (uploadedPaths.length) await supabase.storage.from(imageBucket).remove(uploadedPaths);
        throw error;
      }
      uploadedPaths.push(path);
      rows.push({
        product_id: productId,
        storage_path: path,
        alt_text: name.trim(),
        position: startingPosition + index,
      });
    }

    const { error } = await supabase.from('store_product_images').insert(rows);
    if (error) {
      await supabase.storage.from(imageBucket).remove(uploadedPaths);
      throw error;
    }
  }

  async function submitProduct(event: SubmitEvent) {
    event.preventDefault();
    if (!supabase || !name.trim()) return;
    saving = true;
    setMessage('Guardando artículo…');

    try {
      const categoryId = await resolveCategory();
      const payload = {
        name: name.trim(),
        sku: sku.trim() || null,
        price: Number(price),
        stock: Number(stock || 0),
        description: description.trim(),
        category_id: categoryId,
        is_active: isActive,
        updated_at: new Date().toISOString(),
      };
      const result = editingProduct
        ? await supabase.from('store_products').update(payload).eq('id', editingProduct.id).select('id').single()
        : await supabase.from('store_products').insert(payload).select('id').single();
      if (result.error) throw result.error;

      const { error: costError } = await supabase
        .from('store_product_costs')
        .upsert({ product_id: result.data.id, cost: Number(cost || 0), updated_at: new Date().toISOString() }, { onConflict: 'product_id' });
      if (costError) throw costError;

      await saveVariants(result.data.id, editingProduct?.store_product_variants ?? []);
      await uploadPhotos(result.data.id);
      showForm = false;
      editingProduct = null;
      selectedPhotos = [];
      setMessage('Artículo guardado.');
      await loadCatalog();
    } catch (error) {
      const detail = error instanceof Error ? error.message : '';
      setMessage(detail.includes('duplicate key')
        ? 'Ese SKU ya está asignado a otro artículo o variante.'
        : 'No se pudo guardar. Comprueba los datos y las políticas de Supabase.', true);
    } finally {
      saving = false;
    }
  }

  async function toggleProduct(product: Product) {
    if (!supabase) return;
    const { error } = await supabase
      .from('store_products')
      .update({ is_active: !product.is_active, updated_at: new Date().toISOString() })
      .eq('id', product.id);
    if (error) {
      setMessage('No se pudo cambiar el estado del artículo.', true);
      return;
    }
    await loadCatalog();
    setMessage(product.is_active ? 'Artículo marcado como inactivo.' : 'Artículo activado.');
  }

  function formatPrice(value: number) {
    return new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'EUR' }).format(value);
  }
</script>

<svelte:head>
  <meta name="apple-mobile-web-app-capable" content="yes" />
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
</svelte:head>

{#if view === 'loading'}
  <section class="inventory-card centered"><span class="loader" aria-hidden="true"></span><p>Comprobando acceso…</p></section>
{:else if view === 'setup'}
  <section class="inventory-card centered">
    <p class="inventory-kicker">Yosef Origen · Inventario</p>
    <h1>Falta conectar Supabase</h1>
    <p>Configura las variables públicas de Supabase en Netlify para usar el panel.</p>
  </section>
{:else if view === 'signed-out'}
  <section class="inventory-card centered login-card">
    <a class="inventory-brand" href="/yosef/" aria-label="Yosef Origen">YO</a>
    <p class="inventory-kicker">Panel privado</p>
    <h1>Tu inventario, en un solo lugar</h1>
    <p>Inicia sesión con la cuenta autorizada para administrar los artículos de la tienda.</p>
    <button class="primary-button google-login" type="button" on:click={signInWithGoogle}>
      <span class="google-mark" aria-hidden="true">G</span> Continuar con Google
    </button>
    {#if message}<p class:error={messageError} class="feedback" role="status">{message}</p>{/if}
    <a class="back-link" href="/yosef/tienda">Volver a la tienda</a>
  </section>
{:else if view === 'denied'}
  <section class="inventory-card centered">
    <p class="inventory-kicker">Panel privado</p>
    <h1>Esta cuenta todavía no tiene acceso</h1>
    <p>Sesión iniciada como <strong>{currentUser?.email ?? 'cuenta de Google'}</strong>.</p>
    <p>La cuenta administradora debe añadirse a la lista segura de Supabase después de iniciar sesión por primera vez.</p>
    {#if message}<p class:error={messageError} class="feedback" role="status">{message}</p>{/if}
    <button class="secondary-button" type="button" on:click={signOut}>Cerrar sesión</button>
  </section>
{:else}
  <div class="inventory-shell">
    <header class="inventory-topbar">
      <a class="inventory-brand" href="/yosef/" aria-label="Yosef Origen">YO</a>
      <div class="inventory-title"><p class="inventory-kicker">Yosef Origen</p><h1>Inventario</h1></div>
      <div class="topbar-actions">
        <span class="user-email">{currentUser?.email}</span>
        <button class="install-button" type="button" id="install-app" hidden>Instalar app</button>
        <button class="icon-button" type="button" aria-label="Cerrar sesión" title="Cerrar sesión" on:click={signOut}>↪</button>
      </div>
    </header>

    <section class="inventory-overview" aria-label="Resumen del inventario">
      <article><span>Artículos</span><strong>{products.length}</strong></article>
      <article><span>Activos</span><strong>{products.filter((product) => product.is_active).length}</strong></article>
      <article><span>Agotados</span><strong>{products.filter((product) => product.stock === 0 && product.is_active).length}</strong></article>
    </section>

    <section class="catalog-panel">
      <div class="catalog-toolbar">
        <div><p class="inventory-kicker">Catálogo de tienda</p><h2>Artículos</h2></div>
        <button class="primary-button" type="button" on:click={openNewProduct}>＋ Nuevo artículo</button>
      </div>
      <div class="catalog-filters">
        <label class="search-field"><span class="sr-only">Buscar artículos</span><span aria-hidden="true">⌕</span><input bind:value={search} placeholder="Buscar por nombre, SKU o categoría" /></label>
        <select bind:value={filter} aria-label="Filtrar artículos por estado">
          <option value="all">Todos</option><option value="active">Activos</option><option value="inactive">Inactivos</option>
        </select>
        <button class="refresh-button" type="button" on:click={loadCatalog} disabled={loadingProducts}>Actualizar</button>
      </div>

      {#if message}
        <p class:feedback-error={messageError} class="catalog-feedback" role="status">{message}</p>
      {/if}
      {#if loadingProducts}
        <div class="empty-state"><span class="loader" aria-hidden="true"></span><p>Cargando artículos…</p></div>
      {:else if visibleProducts.length === 0}
        <div class="empty-state"><span class="empty-icon" aria-hidden="true">□</span><h3>{products.length ? 'No encontramos artículos' : 'Tu catálogo está listo'}</h3><p>{products.length ? 'Prueba con otra búsqueda o filtro.' : 'Añade tu primer artículo para empezar a administrar el inventario.'}</p></div>
      {:else}
        <div class="product-list">
          {#each visibleProducts as product (product.id)}
            <article class:product-inactive={!product.is_active} class="product-row">
              <div class="product-thumb">
                {#if product.store_product_images?.length}
                  <img src={imageUrl(product.store_product_images[0].storage_path)} alt={product.store_product_images[0].alt_text || product.name} />
                {:else}<span aria-hidden="true">◇</span>{/if}
              </div>
              <div class="product-name"><h3>{product.name}</h3><span>{product.sku || 'Sin SKU'}{product.store_categories?.name ? ` · ${product.store_categories.name}` : ''}</span></div>
              <div class="product-value"><span>Precio</span><strong>{formatPrice(product.price)}</strong></div>
              <div class="product-value"><span>Existencia</span><strong>{product.stock}</strong></div>
              <span class:status-inactive={!product.is_active} class="status-pill">{product.is_active ? 'Activo' : 'Inactivo'}</span>
              <div class="row-actions">
                <button type="button" on:click={() => openEditProduct(product)}>Editar</button>
                <button type="button" on:click={() => toggleProduct(product)}>{product.is_active ? 'Desactivar' : 'Activar'}</button>
              </div>
            </article>
          {/each}
        </div>
      {/if}
    </section>

    {#if showForm}
      <div class="modal-backdrop" role="presentation" on:click={(event) => event.target === event.currentTarget && closeForm()}>
        <section class="product-modal" role="dialog" aria-modal="true" aria-labelledby="product-form-title">
          <header class="modal-header"><div><p class="inventory-kicker">Catálogo</p><h2 id="product-form-title">{editingProduct ? 'Editar artículo' : 'Nuevo artículo'}</h2></div><button class="icon-button" type="button" aria-label="Cerrar" on:click={closeForm}>×</button></header>
          <form on:submit={submitProduct}>
            <div class="form-grid">
              <label class="field field-wide">Nombre del artículo<input bind:value={name} required maxlength="160" placeholder="Ej. Cuaderno creativo" /></label>
              <label class="field">SKU<input bind:value={sku} maxlength="80" placeholder="Ej. CUAD-001" /></label>
              <label class="field">Categoría<input bind:value={categoryName} list="inventory-categories" maxlength="100" placeholder="Escribe o elige una" /><datalist id="inventory-categories">{#each categories as category}<option value={category.name}></option>{/each}</datalist></label>
              <label class="field">Precio (€)<input bind:value={price} type="number" min="0" step="0.01" required /></label>
              <label class="field">Costo (€)<input bind:value={cost} type="number" min="0" step="0.01" required /></label>
              <label class="field">Existencia<input bind:value={stock} type="number" min="0" step="1" required /></label>
              <label class="field field-wide">Descripción<textarea bind:value={description} rows="3" maxlength="2000" placeholder="Describe el artículo para tu tienda"></textarea></label>
              <label class="field field-wide photo-field">Fotos del artículo<input type="file" accept="image/jpeg,image/png,image/webp,image/avif" multiple on:change={addPhotos} /><small>JPG, PNG, WebP o AVIF; hasta 5 MB por foto.</small></label>
            </div>

            {#if existingImages.length || selectedPhotos.length}
              <div class="photo-preview-list" aria-label="Fotos del artículo">
                {#each existingImages as image (image.id)}
                  <div class="photo-preview"><img src={imageUrl(image.storage_path)} alt={image.alt_text || 'Foto del artículo'} /><button type="button" aria-label="Quitar foto" on:click={() => removeExistingImage(image)}>×</button></div>
                {/each}
                {#each selectedPhotos as photo, index (`${photo.name}-${index}`)}
                  <div class="photo-preview"><img src={URL.createObjectURL(photo)} alt={photo.name} /><button type="button" aria-label="Quitar foto seleccionada" on:click={() => removeSelectedPhoto(index)}>×</button></div>
                {/each}
              </div>
            {/if}

            <div class="variants-heading"><div><h3>Variantes</h3><p>Por ejemplo, talla o color. Cada variante puede tener su propio SKU y existencia.</p></div><button class="secondary-button" type="button" on:click={addVariant}>＋ Añadir variante</button></div>
            {#if variantDrafts.length}
              <div class="variant-list">
                {#each variantDrafts as variant, index (variant.id ?? index)}
                  <div class="variant-row">
                    <label class="field">Nombre<input bind:value={variant.name} placeholder="Talla M / Azul" /></label>
                    <label class="field">SKU<input bind:value={variant.sku} placeholder="Opcional" /></label>
                    <label class="field">Precio<input bind:value={variant.price} type="number" min="0" step="0.01" placeholder="Usar precio base" /></label>
                    <label class="field">Costo<input bind:value={variant.cost} type="number" min="0" step="0.01" placeholder="Usar costo base" /></label>
                    <label class="field">Existencia<input bind:value={variant.stock} type="number" min="0" step="1" /></label>
                    <button class="remove-variant" type="button" aria-label="Quitar variante" on:click={() => removeVariant(index)}>×</button>
                  </div>
                {/each}
              </div>
            {/if}

            <label class="active-toggle"><input type="checkbox" bind:checked={isActive} /> Artículo activo y visible en la tienda</label>
            {#if message}<p class:error={messageError} class="feedback" role="status">{message}</p>{/if}
            <footer class="form-actions"><button class="secondary-button" type="button" on:click={closeForm}>Cancelar</button><button class="primary-button" type="submit" disabled={saving}>{saving ? 'Guardando…' : 'Guardar artículo'}</button></footer>
          </form>
        </section>
      </div>
    {/if}
  </div>
{/if}
