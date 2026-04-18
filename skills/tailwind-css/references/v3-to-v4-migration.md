# Tailwind CSS v3 → v4 Migration Guide

## Overview

Tailwind v4 is a ground-up rewrite. The biggest shift: configuration moves from JavaScript to CSS. No more `tailwind.config.js`, no `content` array. PostCSS is optional via `@tailwindcss/postcss` (for non-Vite bundlers).

## Config File Changes

### Before (v3)
```js
// tailwind.config.js
module.exports = {
  content: ['./src/**/*.{html,js,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          500: '#6366f1',
          600: '#4f46e5',
        },
      },
    },
  },
  plugins: [require('@tailwindcss/typography')],
}
```

### After (v4)
```css
/* input.css */
@import "tailwindcss";
@plugin "@tailwindcss/typography";

@theme {
  --color-primary-500: #6366f1;
  --color-primary-600: #4f46e5;
}

@variant dark (&:where(.dark, .dark *));
```

**Key differences:**
- No `content` array — v4 auto-detects source files
- No `darkMode: 'class'` — use `@variant dark` directive
- No `theme.extend` — define tokens directly in `@theme`
- No `require()` for plugins — use `@plugin` directive
- No PostCSS plugin required — use CLI, Vite plugin, or `@tailwindcss/postcss` for non-Vite bundlers

## New Directives

### `@import "tailwindcss"`

Replaces the three old directives:
```css
/* v3 */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* v4 */
@import "tailwindcss";
```

### `@theme { ... }`

Defines design tokens as CSS custom properties. Tailwind generates utility classes from these automatically.

```css
@theme {
  /* Colors: --color-{name} → bg-{name}, text-{name}, border-{name}, ring-{name} */
  --color-primary-500: #6366f1;
  --color-surface: #ffffff;

  /* Spacing: --spacing-{name} → p-{name}, m-{name}, gap-{name} */
  --spacing-18: 4.5rem;

  /* Font families: --font-{name} → font-{name} */
  --font-display: "Inter", sans-serif;

  /* Font sizes: --text-{name} → text-{name} */
  --text-tiny: 0.625rem;

  /* Border radius: --radius-{name} → rounded-{name} */
  --radius-card: 1rem;

  /* Breakpoints: --breakpoint-{name} → {name}: prefix */
  --breakpoint-xs: 30rem;
}
```

The naming convention is strict: the CSS property prefix determines which utilities are generated.

### `@variant` and `@custom-variant`

`@variant` overrides existing built-in variants. `@custom-variant` defines new ones:

```css
/* Override built-in dark mode to use class-based approach */
@variant dark (&:where(.dark, .dark *));
/* Note: media-based dark mode (prefers-color-scheme) is the default — no config needed */

/* Define entirely new variants with @custom-variant */
@custom-variant hocus (&:hover, &:focus);
```

### `@utility`

Defines custom utility classes (replaces `addUtilities()` from v3 plugin API):

```css
@utility scrollbar-hide {
  scrollbar-width: none;
  &::-webkit-scrollbar { display: none; }
}
/* → Use as class: scrollbar-hide */
```

### `@layer`

Used for base resets and component styles. For custom utilities, prefer `@utility` instead:

```css
@layer base {
  body { @apply bg-surface text-slate-900; }
  h1 { @apply text-2xl font-bold tracking-tight; }
}

@layer components {
  /* Prefer component extraction in your framework instead */
}
```

### `@plugin`

Replaces `plugins` array in config:

```css
@plugin "@tailwindcss/typography";
@plugin "@tailwindcss/forms";
@plugin "@tailwindcss/container-queries";
```

## Build Setup Changes

### v3 (PostCSS-based)
```js
// postcss.config.js
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

### v4 Options

**Option 1: Standalone CLI** (no Node.js)
```bash
# Install
npm install -g @tailwindcss/cli
# or download standalone binary from GitHub releases

# Build
tailwindcss -i input.css -o output.css
tailwindcss -i input.css -o output.css --watch --minify
```

**Option 2: Vite plugin**
```bash
npm install @tailwindcss/vite
```
```ts
// vite.config.ts
import tailwindcss from "@tailwindcss/vite";
export default defineConfig({
  plugins: [tailwindcss()],
});
```

**Option 3: PostCSS plugin** (for non-Vite bundlers)
```bash
npm install @tailwindcss/postcss
```
```js
// postcss.config.js
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

No `autoprefixer` needed — v4 handles vendor prefixes automatically.

## Class Name Changes

| v3 | v4 | Notes |
|----|-----|-------|
| `bg-opacity-50` | `bg-black/50` | Opacity modifier syntax |
| `text-opacity-75` | `text-white/75` | Same for text |
| `border-opacity-25` | `border-black/25` | Same for borders |
| `decoration-clone` | `box-decoration-clone` | Full name now |
| `decoration-slice` | `box-decoration-slice` | Full name now |
| `flex-shrink-0` | `shrink-0` | Already available in v3 |
| `flex-grow` | `grow` | Already available in v3 |
| `shadow-sm` | `shadow-xs` | Shadow scale shifted |
| `shadow` | `shadow-sm` | Shadow scale shifted |
| `shadow-md` | `shadow-md` | Unchanged |
| `ring` | `ring-3` | Default ring width changed |
| `blur` | `blur-sm` | Blur scale shifted |

### Shadow Scale Migration

This is the most common gotcha — the shadow scale shifted down by one:

| v3 | v4 |
|----|----|
| `shadow-sm` | `shadow-xs` |
| `shadow` | `shadow-sm` |
| `shadow-md` | `shadow-md` (same) |
| `shadow-lg` | `shadow-lg` (same) |

### Default Ring Width

```html
<!-- v3: ring = 3px -->
<div class="ring ring-blue-500">

<!-- v4: ring = 1px, use ring-3 for old behavior -->
<div class="ring-3 ring-blue-500">
```

## Content Detection

v4 auto-detects source files — no `content` array needed. It scans all files in your project (respecting `.gitignore`).

To explicitly include/exclude:
```css
@source "../other-package/src";
@source not "../ignored-dir";
```

## Common Migration Pitfalls

1. **Shadows look different** — the scale shifted; `shadow-sm` in v3 → `shadow-xs` in v4
2. **Ring width changed** — `ring` was 3px, now 1px; use `ring-3` for old behavior
3. **No `content` array** — remove it; v4 auto-detects. Use `@source` only for files outside the project
4. **Plugins use `@plugin`** — not `require()` in a JS config
5. **Dark mode config** — `darkMode: 'class'` → `@variant dark (&:where(.dark, .dark *))`
6. **No autoprefixer** — v4 handles it; remove from PostCSS config
7. **`@apply` in `@theme`** — not supported; use raw values in `@theme`
8. **Custom colors** — `theme.extend.colors` → CSS properties in `@theme` with `--color-` prefix
9. **Opacity modifiers are the default** — use `bg-black/50` instead of `bg-opacity-50`
