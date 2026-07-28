import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const laboratorio = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/laboratorio' }),
  schema: z.object({
    title: z.string(),
    category: z.string(),
    parent: z.string().optional(),
    order: z.number(),
    description: z.string().optional(),
  }),
});

const inicio = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/Inicio' }),
  schema: z.object({
    img: z.string(),
    title: z.string(),
    text: z.string(),
  }),
});

export const collections = { laboratorio, inicio };
