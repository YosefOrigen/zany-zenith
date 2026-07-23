import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const laboratorio = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/laboratorio' }),
  schema: z.object({
    title: z.string(),
    group: z.string(),
    anchor: z.string(),
    order: z.number(),
    description: z.string().optional(),
  }),
});

export const collections = { laboratorio };
