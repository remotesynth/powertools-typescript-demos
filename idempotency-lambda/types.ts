export type Request = {
    user: string;
    productId: string;
  };
  
  export type Response = {
    [key: string]: unknown;
  };
  
  export type SubscriptionResult = {
    id: string;
    productId: string;
  };