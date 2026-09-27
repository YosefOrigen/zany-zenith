export const brandConfig = {
  yosef: {
    slug: 'yosef-origen',
    name: 'Yosef Origen',
    title: 'Yosef Origen',
    description: 'Experiencias creativas, juegos y recursos para explorar.',
    theme: 'yosef',
    accent: '#7c3aed',
  },
} as const;

export type BrandKey = keyof typeof brandConfig;
