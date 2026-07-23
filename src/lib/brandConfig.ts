export const brandConfig = {
  origen: {
    slug: 'origen-estudio',
    name: 'Origen Estudio',
    title: 'Origen Estudio',
    description: 'Diseño, estrategia y contenidos con identidad propia.',
    theme: 'origen',
    accent: '#1d4ed8',
  },
  yosef: {
    slug: 'yosef-origen',
    name: 'Yosef Origen',
    title: 'Yosef Origen',
    description: 'Experiencias creativas, juegos y recursos para explorar.',
    theme: 'yosef',
    accent: '#7c3aed',
  },
  bellum: {
    slug: 'bellum',
    name: 'Bellum',
    title: 'Bellum',
    description: 'Catálogos y productos con una voz propia.',
    theme: 'bellum',
    accent: '#0f766e',
  },
} as const;

export type BrandKey = keyof typeof brandConfig;
