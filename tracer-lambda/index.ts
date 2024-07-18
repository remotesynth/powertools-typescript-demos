import { Tracer } from '@aws-lambda-powertools/tracer';

const tracer = new Tracer({ serviceName: 'localstack' });

export const handler = async (_event, _context): Promise<void> => {
  tracer.getSegment();
};