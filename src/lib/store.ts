/** Tipos que comparte la tienda con la futura persistencia de pedidos. */
export interface StoreOrderItem { productId:string; name:string; quantity:number; unitPrice:number }
export type StoreOrderStatus = 'pending' | 'preparing' | 'shipped' | 'delivered' | 'cancelled';
export interface StoreOrder { id:string; trackingToken:string; customer:{name:string;phone:string;address:string;notes?:string}; items:StoreOrderItem[]; total:number; paymentMethod:'cash_on_delivery'; status:StoreOrderStatus; createdAt:string }
