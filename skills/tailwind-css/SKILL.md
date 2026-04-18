---
name: tailwind-css
description: >-
  Use when writing Tailwind CSS v4 code, configuring Tailwind v4 with @theme
  or @variant directives, migrating from Tailwind v3 to v4, setting up
  CSS-native config (no tailwind.config.js), defining semantic color tokens,
  implementing dark mode with class-based @variant, creating design system
  tokens, or styling components with utility classes. Covers @import
  "tailwindcss", @theme blocks, @variant, @layer, CSS custom properties for
  colors, and common layout/component patterns.
version: 1.0.0
tags: [css, frontend, design]
targets: [claude]
---

# Tailwind CSS v4

Tailwind v4 replaces JS config with **CSS-native configuration**. No `tailwind.config.js` — pure CSS with new directives. PostCSS is optional via `@tailwindcss/postcss`.

For v3→v4 migration details, see `references/v3-to-v4-migration.md`.
For design system patterns (colors, typography, spacing, components), see `references/design-system.md`.

## CSS-Native Setup

```css
/* input.css */
@import "tailwindcss";

@theme {
  --color-primary-50: #eef2ff;
  --color-primary-100: #e0e7ff;
  --color-primary-500: #6366f1;
  --color-primary-600: #4f46e5;
  --color-primary-700: #4338ca;
  /* ... full scale ... */

  --color-surface: #ffffff;
  --color-surface-dark: #0f172a;
  --color-border: #e2e8f0;
  --color-border-dark: #334155;
  --color-muted: #64748b;
}

@variant dark (&:where(.dark, .dark *));

@layer base {
  body {
    @apply bg-surface text-slate-900 dark:bg-surface-dark dark:text-slate-100;
  }
}
```

`★ Insight ─────────────────────────────────────`
- `@import "tailwindcss"` replaces the old `@tailwind base/components/utilities` directives
- `@theme` defines design tokens as CSS custom properties — Tailwind auto-generates utility classes from them (e.g., `--color-primary-500` → `bg-primary-500`, `text-primary-500`)
- `@variant dark` with `&:where(.dark, .dark *)` enables class-based dark mode via a `.dark` class on the root element
`─────────────────────────────────────────────────`

## Semantic Color Tokens

Define semantic names in `@theme` instead of using raw Tailwind colors:

| Token | Purpose | Example classes |
|-------|---------|-----------------|
| `primary-*` | Brand, CTAs, active states | `bg-primary-500`, `text-primary-600` |
| `accent-*` | Highlights, badges, warnings | `bg-accent-100`, `text-accent-700` |
| `surface` / `surface-dark` | Page/card backgrounds | `bg-surface dark:bg-surface-dark` |
| `border` / `border-dark` | Borders, dividers | `border-border dark:border-border-dark` |
| `muted` | Secondary/helper text | `text-muted` |

```html
<!-- Good: semantic tokens -->
<div class="bg-surface text-muted border-border">

<!-- Avoid: raw colors for themed elements -->
<div class="bg-white text-gray-500 border-gray-200">
```

## Dark Mode

Class-based dark mode using `@variant dark`:

```html
<!-- Toggle .dark on <html> or <body> -->
<html class="dark">

<!-- Dual-mode styling -->
<div class="bg-surface dark:bg-surface-dark border-border dark:border-border-dark">
<p class="text-slate-700 dark:text-slate-300">
```

**Always add `dark:` variants** for backgrounds, borders, and text colors on every visual element.

Prevent FOUC by applying the theme class before first paint (inline script or server-rendered class).

## Common Layout Patterns

```html
<!-- Two-column: sidebar + content -->
<div class="flex gap-6">
  <aside class="w-64 shrink-0">...</aside>
  <div class="min-w-0 flex-1">...</div>
</div>

<!-- Full-height with scroll -->
<div class="flex h-[calc(100vh-8rem)] flex-col">
  <div class="flex-1 overflow-y-auto">...</div>
  <div><!-- sticky footer/input --></div>
</div>

<!-- Responsive padding -->
<div class="px-4 sm:px-6 lg:px-8">
<div class="mx-auto max-w-7xl">
```

## Component Patterns

```html
<!-- Card -->
<div class="rounded-2xl bg-white p-4 ring-1 ring-slate-200
            dark:bg-slate-900 dark:ring-slate-800">

<!-- Primary button -->
<button class="rounded-xl bg-primary-500 px-4 py-2.5 text-sm font-semibold
               text-white shadow-sm hover:bg-primary-600 active:bg-primary-700">

<!-- Input field -->
<input class="w-full rounded-xl bg-white px-3 py-2.5 text-sm ring-1 ring-slate-300
              placeholder:text-slate-400 focus:ring-2 focus:ring-primary-500
              dark:bg-slate-900 dark:ring-slate-700 dark:text-white">

<!-- Prose / markdown -->
<article class="prose prose-sm max-w-none dark:prose-invert">
```

## Elevation: ring vs border

Prefer `ring-1` over `border` — rings don't affect layout sizing, preventing 1px shifts on hover/focus state changes.

```html
<!-- Cards: ring for borders -->
<div class="ring-1 ring-slate-200 dark:ring-slate-800">

<!-- Dark mode elevation: replace shadows with subtle rings -->
<div class="shadow-md dark:shadow-none dark:ring-1 dark:ring-white/10">
```

| Level | Usage | Classes |
|-------|-------|---------|
| None | Default cards | `ring-1 ring-slate-200 dark:ring-slate-800` |
| Low | Raised cards | `shadow-sm` |
| Medium | Dropdowns | `shadow-md` |
| High | Modals | `shadow-xl` |

## Build Options

Tailwind v4 supports three build methods:

```bash
# Standalone CLI (no Node.js required)
tailwindcss -i input.css -o output.css
tailwindcss -i input.css -o output.css --watch

# Vite plugin
# vite.config.ts
import tailwindcss from "@tailwindcss/vite";
export default { plugins: [tailwindcss()] };

# PostCSS plugin (for Webpack, Parcel, etc.)
# npm install @tailwindcss/postcss
# postcss.config.js: { plugins: { "@tailwindcss/postcss": {} } }
```

## Key Conventions

1. **Semantic tokens** — define colors in `@theme`, use token names (`primary-*`, `surface`, `border`) not raw palette names
2. **Dark mode on every element** — always pair light styles with `dark:` variants
3. **No CSS-in-JS** — style with utility classes; extract components (React/Vue/templ) instead of CSS component classes
4. **Minimal custom CSS** — only `@theme` tokens and `@layer base` resets in your input CSS
5. **`ring-1` over `border`** — for borders that shouldn't affect layout
6. **Mobile-first** — default styles are mobile; use `sm:`, `md:`, `lg:` for larger screens
