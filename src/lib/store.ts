/** Modelo listo para la futura persistencia de pedidos en Supabase. */
export interface StoreOrderItem { productId:string; name:string; quantity:number; unitPrice:number }
export interface StoreOrder { id:string; customer:{name:string;phone:string;address:string;notes?:string}; items:StoreOrderItem[]; total:number; paymentMethod:'cash_on_delivery'; status:'pending'; createdAt:string }
export const supabaseReady=Boolean(import.meta.env.PUBLIC_SUPABASE_URL && import.meta.env.PUBLIC_SUPABASE_ANON_KEY);
// Añadir credenciales mediante secretos de entorno al conectar el servicio.
