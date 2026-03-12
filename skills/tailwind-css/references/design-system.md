# Design System Patterns with Tailwind v4

Reusable design system patterns using Tailwind v4's `@theme` tokens. Adapt colors, spacing, and components to your project.

## Color Palette Structure

### Defining a Color System in `@theme`

A well-structured palette has four layers: **primary**, **accent**, **semantic**, and **neutrals**.

```css
@theme {
  /* Primary — brand, CTAs, active states */
  --color-primary-50: #eef2ff;
  --color-primary-100: #e0e7ff;
  --color-primary-200: #c7d2fe;
  --color-primary-300: #a5b4fc;
  --color-primary-400: #818cf8;
  --color-primary-500: #6366f1;   /* main brand */
  --color-primary-600: #4f46e5;   /* hover */
  --color-primary-700: #4338ca;   /* active/pressed */
  --color-primary-800: #3730a3;   /* dark surfaces */
  --color-primary-900: #312e81;   /* dark backgrounds */
  --color-primary-950: #1e1b4e;

  /* Accent — highlights, achievements, featured items */
  --color-accent-50: #fffbeb;
  --color-accent-100: #fef3c7;
  --color-accent-200: #fde68a;
  --color-accent-400: #e5a820;
  --color-accent-500: #a8680b;    /* main accent */
  --color-accent-600: #8c5709;

  /* Semantic aliases */
  --color-surface: #ffffff;
  --color-surface-dark: #0f172a;
  --color-border: #e2e8f0;
  --color-border-dark: #334155;
  --color-muted: #64748b;
}
```

### Semantic Color Mapping

Map roles to tokens rather than raw values:

| Role | Token | Usage |
|------|-------|-------|
| Success | `green-500` / `green-100` / `green-700` or custom `success-*` | Confirmations, completed states |
| Error | `red-500` / `red-100` / `red-700` | Form errors, destructive actions, error badges |
| Warning | `accent-500` / `accent-100` | Pending actions, warnings |
| Info | `sky-500` / `sky-100` | Info badges, neutral status |

### Choosing a Neutral Scale

Pick **one** neutral scale and stick to it:

| Scale | Character | Pairs well with |
|-------|-----------|-----------------|
| `slate` | Warm, blue undertone | Indigo, blue, violet |
| `zinc` | True neutral | Any primary |
| `gray` | Warm neutral | Warm primaries (amber, orange) |
| `stone` | Very warm | Earth tones |
| `neutral` | Pure gray | Minimal/monochrome designs |

**Never mix neutral scales** (e.g., don't use `gray-*` for text and `slate-*` for backgrounds).

## Typography Scale

| Role | Size | Weight | Tracking | Usage |
|------|------|--------|----------|-------|
| Display | `text-2xl` (24px) | Bold (700) | `tracking-tight` | Page titles |
| Heading | `text-xl` (20px) | Semibold (600) | `tracking-tight` | Section titles |
| Subheading | `text-base` (16px) | Semibold (600) | normal | Card titles, labels |
| Body | `text-sm` (14px) | Regular (400) | normal | Default text |
| Caption | `text-xs` (12px) | Medium (500) | `tracking-wide` | Timestamps, metadata |
| Data | `text-lg` (18px) | Bold (700) | `tabular-nums` | Numbers that should align |

**Tips:**
- Headings: tight tracking + semibold/bold for a polished feel
- `tabular-nums` on numeric data so digits align in columns
- Custom fonts via `@theme`: `--font-display: "Inter", sans-serif;`

## Spacing & Sizing

Base unit: 0.25rem / 4px at default 16px root font size (Tailwind default).

| Use case | Value | Class |
|----------|-------|-------|
| Inline padding (badges) | 8px / 2px | `px-2 py-0.5` |
| Button padding | 16px / 10px | `px-4 py-2.5` |
| Card internal padding | 16px | `p-4` |
| Section gap | 24px | `gap-6` |
| Page padding (mobile) | 16px | `px-4` |
| Page padding (desktop) | 24px | `px-6` |

**Touch targets**: minimum 44x44px on all interactive elements (mobile).

## Border Radius Patterns

| Element | Radius | Class |
|---------|--------|-------|
| Buttons | 12px | `rounded-xl` |
| Cards | 16px | `rounded-2xl` |
| Inputs | 12px | `rounded-xl` |
| Badges / pills | Full | `rounded-full` |
| Avatars | Full | `rounded-full` |
| Modals / sheets | 24px | `rounded-3xl` or `rounded-t-3xl` |

Custom radii via `@theme`: `--radius-card: 1rem;` → `rounded-card`

## Elevation & Borders

Prefer `ring-1` over `border` — rings don't affect layout, preventing 1px shifts on state changes.

| Level | Usage | Classes |
|-------|-------|---------|
| None | Default cards | `ring-1 ring-slate-200 dark:ring-slate-800` |
| Low | Raised cards, buttons | `shadow-sm` |
| Medium | Dropdowns, popovers | `shadow-md` |
| High | Modals, sheets | `shadow-xl` |

**Dark mode elevation**: replace visible shadows with `ring-1 ring-white/10`.

## Dark Mode Token Mapping

| Element | Light | Dark |
|---------|-------|------|
| Page bg | `slate-50` | `slate-950` |
| Card bg | `white` | `slate-900` |
| Card border | `ring-slate-200` | `ring-slate-800` |
| Heading text | `slate-900` | `white` |
| Body text | `slate-600` | `slate-400` |
| Primary button | `primary-500` | `primary-500` (same) |
| Muted surface | `slate-100` | `slate-800` |
| Separator | `slate-200` | `slate-800` |

Use semantic tokens (`surface`, `surface-dark`, `border`, `border-dark`) in `@theme` to avoid repeating these pairs.

## Component Primitive Styles

### Card

```html
<div class="rounded-2xl bg-white p-4 ring-1 ring-slate-200
            dark:bg-slate-900 dark:ring-slate-800">
```

**Variants:**

| Variant | Additional classes |
|---------|--------------------|
| Active / Selected | `bg-primary-500 text-white ring-0` |
| Highlighted | `ring-2 ring-primary-400 bg-primary-50` |
| Disabled | `bg-slate-100 text-slate-400 opacity-60` |

### Button Variants

**Primary:**
```html
<button class="rounded-xl bg-primary-500 px-4 py-2.5 text-sm font-semibold
               text-white shadow-sm hover:bg-primary-600 active:bg-primary-700
               active:shadow-none">
```

**Outline:**
```html
<button class="rounded-xl bg-transparent px-4 py-2.5 text-sm
               text-slate-700 ring-1 ring-slate-300
               hover:bg-slate-50 dark:text-slate-300
               dark:ring-slate-700 dark:hover:bg-slate-800">
```

**Destructive:**
```html
<button class="rounded-xl bg-red-500 px-4 py-2.5 text-sm font-semibold
               text-white hover:bg-red-600 active:bg-red-700">
```

**Ghost:**
```html
<button class="rounded-xl bg-transparent px-4 py-2.5 text-sm
               text-slate-600 hover:bg-slate-100
               dark:text-slate-400 dark:hover:bg-slate-800">
```

### Input Field

```html
<input class="w-full rounded-xl bg-white px-3 py-2.5 text-sm
              text-slate-900 ring-1 ring-slate-300
              placeholder:text-slate-400
              focus:ring-2 focus:ring-primary-500
              dark:bg-slate-900 dark:text-white dark:ring-slate-700">
```

### Badge Variants

| Variant | Classes |
|---------|---------|
| Success | `bg-green-100 text-green-700 rounded-full px-2 py-0.5 text-xs` |
| Error | `bg-red-100 text-red-700 rounded-full px-2 py-0.5 text-xs` |
| Warning | `bg-accent-100 text-accent-700 rounded-full px-2 py-0.5 text-xs` |
| Featured | `bg-accent-500 text-white rounded-full px-2 py-0.5 text-xs` |
| Info | `bg-sky-100 text-sky-700 rounded-full px-2 py-0.5 text-xs` |

## Motion & Transitions

| Type | Duration | Easing |
|------|----------|--------|
| Hover / focus | 150ms | `ease-out` |
| Page transitions | 200ms | `ease-in-out` |
| Modal enter | 250ms | `ease-out` |
| Modal leave | 150ms | `ease-in` |
| Layout animations | 300ms | spring |
| Skeleton pulse | 1.5s | `ease-in-out` infinite |

```html
<!-- Hover transition -->
<button class="transition-colors duration-150 ease-out hover:bg-primary-600">

<!-- Reduced motion -->
<style>
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
</style>
```

## Responsive Layout Patterns

### Mobile-First Breakpoints

| Breakpoint | Width | Typical layout change |
|------------|-------|-----------------------|
| Default | < 640px | Single column, full-width cards |
| `sm` | >= 640px | Minor spacing adjustments |
| `md` | >= 768px | Two-column layouts possible |
| `lg` | >= 1024px | Sidebar nav, wider content |
| `xl` | >= 1280px | Multi-column dashboards |

### Common Patterns

```html
<!-- Responsive grid -->
<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">

<!-- Sidebar layout (desktop only) -->
<div class="lg:flex lg:gap-6">
  <aside class="hidden lg:block lg:w-64 lg:shrink-0">...</aside>
  <main class="min-w-0 flex-1">...</main>
</div>

<!-- Centered content with max-width -->
<div class="mx-auto max-w-2xl px-4 sm:px-6 lg:px-8">
```
