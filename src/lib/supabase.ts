import { createClient, type SupabaseClient } from '@supabase/supabase-js';

const projectUrl =
  import.meta.env.PUBLIC_SUPABASE_URL ??
  import.meta.env.PUBLIC_SUPABASE_DATABASE_URL;
const publishableKey =
  import.meta.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
  import.meta.env.PUBLIC_SUPABASE_ANON_KEY;

/** Indica si el sitio tiene las variables públicas de Supabase configuradas. */
export const supabaseReady = Boolean(projectUrl && publishableKey);

let client: SupabaseClient | undefined;

/** Crea el cliente de navegador cuando existe la configuración pública. */
export function getSupabaseClient(): SupabaseClient | null {
  if (!projectUrl || !publishableKey) return null;
  client ??= createClient(projectUrl, publishableKey);
  return client;
}
