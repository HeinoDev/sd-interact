import { icons, type LucideIcon } from 'lucide-react';

/**
 * An option's icon. Font Awesome classes ('fa-solid fa-gun', as ox_target options use) render as Font
 * Awesome; anything else is a lucide icon name, kebab or Pascal case ('phone', 'hand-coins', 'Lock').
 * An unknown name falls back to a plain dot, so a typo never leaves the tile empty.
 */
export function Icon({ name, size }: { name?: string; size: number }) {
  if (name && name.includes('fa-')) {
    return <i className={name} style={{ fontSize: size * 0.86, lineHeight: 1 }} aria-hidden />;
  }
  const Lucide = lookup(name) ?? icons.Dot;
  return <Lucide size={size} strokeWidth={2.25} aria-hidden />;
}

function lookup(name?: string): LucideIcon | undefined {
  if (!name) return undefined;
  const pascal = name
    .split(/[-_\s]+/)
    .filter(Boolean)
    .map((p) => p[0].toUpperCase() + p.slice(1))
    .join('');
  return (icons as Record<string, LucideIcon>)[pascal] ?? (icons as Record<string, LucideIcon>)[name];
}
