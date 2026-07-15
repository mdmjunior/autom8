import {
  mkdirSync,
  readFileSync,
  readdirSync,
  statSync,
  writeFileSync
} from 'node:fs';

import path from 'node:path';
import {
  fileURLToPath
} from 'node:url';

const currentFile = fileURLToPath(
  import.meta.url
);

const siteDirectory = path.resolve(
  path.dirname(currentFile),
  '..'
);

const pagesDirectory = path.join(
  siteDirectory,
  'src',
  'pages'
);

const publicDirectory = path.join(
  siteDirectory,
  'public'
);

const documentationPath = path.join(
  siteDirectory,
  'src',
  'data',
  'documentation.json'
);

const siteUrl = 'https://autom8.oslabs.com.br';

const manifestIcons = [
  {
    "src": "/branding/favicon.svg",
    "sizes": "any",
    "type": "image/svg+xml",
    "purpose": "any"
  },
  {
    "src": "/branding/logo-autom8-icon.svg",
    "sizes": "any",
    "type": "image/svg+xml",
    "purpose": "any"
  },
  {
    "src": "/branding/favicon.png",
    "sizes": "any",
    "type": "image/png",
    "purpose": "any"
  },
  {
    "src": "/branding/logo-autom8-horizontal.svg",
    "sizes": "any",
    "type": "image/svg+xml",
    "purpose": "any"
  },
  {
    "src": "/branding/logo-autom8-site.png",
    "sizes": "any",
    "type": "image/png",
    "purpose": "any"
  },
  {
    "src": "/branding/mascot-body-autom8.png",
    "sizes": "any",
    "type": "image/png",
    "purpose": "any"
  }
];


const walkFiles = (directory) => {
  const entries = readdirSync(
    directory
  );

  const files = [];

  for (const entry of entries) {
    const absolutePath = path.join(
      directory,
      entry
    );

    const stats = statSync(
      absolutePath
    );

    if (stats.isDirectory()) {
      files.push(
        ...walkFiles(absolutePath)
      );

      continue;
    }

    files.push(
      absolutePath
    );
  }

  return files;
};


const pageFiles = walkFiles(
  pagesDirectory
).filter((file) => {
  const relativePath = path.relative(
    pagesDirectory,
    file
  );

  return (
    file.endsWith('.astro') &&
    !relativePath
      .split(path.sep)
      .some((part) => (
        part.startsWith('_') ||
        part.includes('[') ||
        part.includes(']')
      ))
  );
});


const routeFromPage = (file) => {
  const relativePath = path.relative(
    pagesDirectory,
    file
  ).replaceAll(
    path.sep,
    '/'
  );

  const withoutExtension =
    relativePath.replace(
      /\.astro$/,
      ''
    );

  if (withoutExtension === 'index') {
    return '/';
  }

  if (withoutExtension.endsWith('/index')) {
    return (
      '/' +
      withoutExtension
        .slice(0, -'/index'.length)
        .replace(/^\/+|\/+$/g, '') +
      '/'
    );
  }

  return (
    '/' +
    withoutExtension
      .replace(/^\/+|\/+$/g, '') +
    '/'
  );
};


const routes = Array.from(
  new Set(
    pageFiles.map(
      routeFromPage
    )
  )
).sort((first, second) => {
  if (first === '/') {
    return -1;
  }

  if (second === '/') {
    return 1;
  }

  return first.localeCompare(
    second,
    'pt-BR'
  );
});


let releaseDate = '';

try {
  const documentation = JSON.parse(
    readFileSync(
      documentationPath,
      'utf8'
    )
  );

  releaseDate =
    documentation?.product?.currentDate ||
    '';
} catch {
  releaseDate = '';
}


mkdirSync(
  publicDirectory,
  {
    recursive: true
  }
);


const robots = [
  'User-agent: *',
  'Allow: /',
  '',
  `Sitemap: ${siteUrl}/sitemap.xml`,
  ''
].join('\n');

writeFileSync(
  path.join(
    publicDirectory,
    'robots.txt'
  ),
  robots,
  'utf8'
);


const sitemapUrls = routes.map(
  (route) => {
    const location =
      route === '/'
        ? `${siteUrl}/`
        : `${siteUrl}${route}`;

    const lastModified =
      releaseDate
        ? `\n    <lastmod>${releaseDate}</lastmod>`
        : '';

    return [
      '  <url>',
      `    <loc>${location}</loc>${lastModified}`,
      '  </url>'
    ].join('\n');
  }
);

const sitemap = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
  ...sitemapUrls,
  '</urlset>',
  ''
].join('\n');

writeFileSync(
  path.join(
    publicDirectory,
    'sitemap.xml'
  ),
  sitemap,
  'utf8'
);


const manifest = {
  name: 'AutoM8 - Linux Management Suite',
  short_name: 'AutoM8',
  description:
    'CLI local para instalação, manutenção e administração de sistemas Linux.',
  lang: 'pt-BR',
  start_url: '/',
  scope: '/',
  display: 'standalone',
  background_color: '#020617',
  theme_color: '#020617',
  orientation: 'any',
  categories: [
    'utilities',
    'developer-tools',
    'productivity'
  ],
  icons: manifestIcons
};

writeFileSync(
  path.join(
    publicDirectory,
    'site.webmanifest'
  ),
  (
    JSON.stringify(
      manifest,
      null,
      2
    ) + '\n'
  ),
  'utf8'
);


console.log(
  `[AutoM8] Metadados públicos gerados: ${routes.length} rota(s).`
);

for (const route of routes) {
  console.log(
    `[AutoM8] Sitemap: ${route}`
  );
}
