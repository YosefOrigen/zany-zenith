---
title: "Godot: De un ataque simple a un COMBO de 2 golpes"
category: por-donde-empezar
order: 11
description: Ejemplo de cómo incrustar un video de YouTube en un artículo.
---
## Video de ejemplo

Puedes incrustar videos de YouTube usando HTML estándar. Aquí tienes un ejemplo **funcional**:


<div style="position:relative;width:100%;max-width:720px;margin:24px 0;aspect-ratio:16/9;border-radius:16px;overflow:hidden;background:#000;box-shadow:0 8px 30px rgba(0,0,0,.12)">
  <iframe 
    src="https://www.youtube-nocookie.com/embed/hYCun5c8ztA?si=w3L1egQre7l5O3Eg" 
    style="position:absolute;top:0;left:0;width:100%;height:100%;border:0" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
    allowfullscreen 
  ></iframe>
</div>


### Cómo usarlo en tus artículos

Copia este código **exactamente** en tu archivo `.md` (sin los ```html, solo el HTML directo):



Reemplaza `TU_ID_DE_VIDEO` con el ID de tu video (los caracteres después de `v=` en la URL de YouTube).

### Importante
- El HTML debe estar **sin sangría** (sin espacios al inicio de línea)
- No lo envuelvas en ```html ... ```, ponlo directamente
- Si usas tabs o 4 espacios al inicio, Markdown lo tratará como código

### Características
- **Responsive**: se adapta a cualquier tamaño de pantalla
- **Optimizado**: usa `loading="lazy"` para cargar solo cuando es visible
- **Privacidad**: usa `youtube-nocookie.com` para respetar la privacidad
- **Sin extensiones**: funciona con HTML puro en cualquier `.md`
