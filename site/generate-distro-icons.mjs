import * as simpleIcons from 'simple-icons';
import { mkdirSync, writeFileSync } from 'node:fs';

const outputDir = 'public/branding/distros';

const distros = [
  { file: 'ubuntu.svg', slug: 'ubuntu', title: 'Ubuntu' },
  { file: 'debian.svg', slug: 'debian', title: 'Debian' },
  { file: 'fedora.svg', slug: 'fedora', title: 'Fedora' },
  { file: 'rocky.svg', slug: 'rockylinux', title: 'Rocky Linux' },
  { file: 'alma.svg', slug: 'almalinux', title: 'AlmaLinux' },
  { file: 'opensuse.svg', slug: 'opensuse', title: 'openSUSE' },
  { file: 'arch.svg', slug: 'archlinux', title: 'Arch Linux' },
  { file: 'manjaro.svg', slug: 'manjaro', title: 'Manjaro' }
];

function findIcon(distro) {
  return Object.values(simpleIcons).find((icon) => {
    if (!icon || typeof icon !== 'object') return false;

    const slug = String(icon.slug || '').toLowerCase();
    const title = String(icon.title || '').toLowerCase();

    return slug === distro.slug.toLowerCase() || title === distro.title.toLowerCase();
  });
}

mkdirSync(outputDir, { recursive: true });

for (const distro of distros) {
  const icon = findIcon(distro);

  if (!icon) {
    throw new Error(`Ícone não encontrado no simple-icons: ${distro.title}`);
  }

  const color = `#${icon.hex}`;
  const svg = `<svg width="96" height="96" viewBox="0 0 96 96" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="${distro.title}">
  <rect width="96" height="96" rx="28" fill="#0B1220"/>
  <rect x="8" y="8" width="80" height="80" rx="24" fill="${color}" fill-opacity="0.12" stroke="${color}" stroke-width="2.5"/>
  <svg x="26" y="26" width="44" height="44" viewBox="0 0 24 24" fill="${color}" xmlns="http://www.w3.org/2000/svg">
    <path d="${icon.path}"/>
  </svg>
</svg>
`;

  writeFileSync(`${outputDir}/${distro.file}`, svg, 'utf8');
  console.log(`Gerado: ${outputDir}/${distro.file}`);
}
