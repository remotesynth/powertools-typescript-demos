import { randomUUID } from 'node:crypto';
import { makeIdempotent } from '@aws-lambda-powertools/idempotency';
import { DynamoDBPersistenceLayer } from '@aws-lambda-powertools/idempotency/dynamodb';
import type { Context } from 'aws-lambda';
import type { Request, Response, SubscriptionResult } from './types.js';
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

const persistenceStore = new DynamoDBPersistenceLayer({
  tableName: process.env.IDEMPOTENCY_TABLE_NAME as string,
});

const createSubscriptionPayment = async (
  event: Request
): Promise<SubscriptionResult> => {
  const id = randomUUID();
  await dynamo.send(
    new PutCommand({
      TableName: process.env.PAYMENT_TABLE_NAME,
      Item: {
        id: id,
        productid: event.productId,
        user: event.user,
      },
    })
  );
  
  return {
    id: id,
    productId: event.productId,
  };
};


export const handler = makeIdempotent(
  async (event: Request, _context: Context): Promise<Response> => {
    try {
      const payment = await createSubscriptionPayment(event);

      const body = {
        message: 'Payment created',
        paymentId: payment.id,
      };

      return {
        statusCode: 200,
        body: JSON.stringify(body),
      };
    } catch (error) {
      throw new Error('Error creating payment');
    }
  },
  {
    persistenceStore,
  }
);