---
title: INICIO
category: Por donde empezar
order: 1
description: Guía esencial para comenzar tu viaje en el desarrollo de videojuegos.
---

Empieza por los conceptos esenciales del motor que elijas y crea prototipos breves. Un movimiento sencillo, una colisión o un menú funcional son ejercicios valiosos para formar tu propio flujo de trabajo.

Bienvenido al laboratorio. Aquí encontrarás todo lo que necesitas para transformar tus ideas en experiencias interactivas.

## Hardware recomendado

No necesitas una supercomputadora para empezar. La mayoría de motores modernos funcionan bien con:

- **CPU**: Cualquier procesador de 4 núcleos o superior
- **RAM**: 8 GB mínimo (16 GB recomendados)
- **GPU**: Tarjeta gráfica dedicada (opcional para motores 2D)
- **Disco**: SSD para tiempos de carga rápidos

## Software necesario

Para empezar solo necesitas:

1. **Un motor de videojuegos** (Godot, Unity, Unreal, etc.)
2. **Un editor de código** (VS Code, Vim, etc.)
3. **Herramientas de arte** (opcional según tu rol)

## Organización del proyecto

Mantén una estructura de carpetas clara desde el inicio:

```
mi-juego/
├── assets/
│   ├── sprites/
│   ├── sonidos/
│   └── fuentes/
├── scripts/
├── escenas/
└── documentacion/
```
## ¿Qué es un motor?

Un motor de videojuegos reúne sistemas y herramientas para crear, renderizar y ejecutar una experiencia interactiva. Incluye elementos como física, audio, animación, renderizado y gestión de escenas.

No necesitas dominar cada sistema desde el primer día. Lo importante es entender cómo se relacionan y aprender a construir proyectos pequeños con ellos.

## Motores más populares

| Motor   | Lenguaje principal | Ideal para        |
|---------|-------------------|-------------------|
| Godot   | GDScript / C#     | 2D y 3D ligero    |
| Unity   | C#                | 2D, 3D, móvil     |
| Unreal  | C++ / Blueprints  | 3D de alta gama   |
| GameMaker | GML             | 2D clásico        |

## ¿Cuál elegir?

Depende de tus objetivos:
- **Godot**: Open source, liviano, ideal para aprender
- **Unity**: Gran comunidad, versátil, mucho soporte
- **Unreal**: Potencia gráfica, ideal para equipos grandes


## Godot vs Unity

| Aspecto         | Godot                      | Unity                     |
|----------------|----------------------------|---------------------------|
| Peso           | ~50 MB                     | ~3 GB                     |
| Open Source    | Sí                         | No                        |
| 2D             | Excelente (nativo)         | Bueno (físicas 2D)        |
| 3D             | Bueno (mejorando)          | Excelente                 |
| Curva de aprendizaje | Baja                 | Media                     |

## Godot vs Unreal

Unreal está orientado a grandes producciones. Godot es más adecuado para:
- Indies y proyectos pequeños
- Aprendizaje y prototipado rápido
- Juegos 2D y 3D de escala moderada

## Godot vs GameMaker

GameMaker es ideal para juegos 2D clásicos, pero Godot ofrece:
- Mayor flexibilidad
- Gratuito y open source
- Soporte 3D integrado

## SDL

Simple DirectMedia Layer proporciona acceso de bajo nivel a:
- Ventanas y gráficos
- Entrada de teclado, ratón y mando
- Audio

Ideal para aprender los fundamentos del desarrollo de videojuegos.

## Raylib

Una librería diseñada específicamente para aprender programación de juegos:

- Sintaxis simple y clara
- Múltiples lenguajes soportados
- Ideal para prototipos y educación

## OpenGL

El estándar gráfico de más bajo nivel. Recomendado solo si:
- Quieres entender el pipeline gráfico
- Necesitas control total del renderizado
- Tienes experiencia previa en desarrollo

