import {
  existsSync,
  readFileSync,
  readdirSync,
  statSync
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

const distDirectory = path.join(
  siteDirectory,
  'dist'
);

const publicDirectory = path.join(
  siteDirectory,
  'public'
);

const siteUrl =
  'https://autom8.oslabs.com.br';


const walkFiles = (directory) => {
  if (!existsSync(directory)) {
    return [];
  }

  const files = [];

  for (
    const entry
    of readdirSync(directory)
  ) {
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


const htmlFiles = walkFiles(
  distDirectory
).filter(
  (file) => file.endsWith('.html')
);


if (htmlFiles.length === 0) {
  throw new Error(
    'Nenhuma página HTML foi encontrada em dist.'
  );
}


const errors = [];
const warnings = [];


const addError = (
  file,
  message
) => {
  const relativeFile = path.relative(
    siteDirectory,
    file
  );

  errors.push(
    `${relativeFile}: ${message}`
  );
};


const addWarning = (
  file,
  message
) => {
  const relativeFile = path.relative(
    siteDirectory,
    file
  );

  warnings.push(
    `${relativeFile}: ${message}`
  );
};


const countMatches = (
  content,
  expression
) => (
  Array.from(
    content.matchAll(expression)
  ).length
);


const getAttribute = (
  tag,
  attribute
) => {
  const expression = new RegExp(
    `\\b${attribute}\\s*=\\s*["']([^"']*)["']`,
    'i'
  );

  return tag.match(
    expression
  )?.[1] ?? null;
};


const stripQueryAndHash = (
  value
) => (
  value
    .split('#')[0]
    .split('?')[0]
);


const currentRouteForFile = (
  htmlFile
) => {
  const relativeFile = path.relative(
    distDirectory,
    htmlFile
  ).replaceAll(
    path.sep,
    '/'
  );

  if (relativeFile === 'index.html') {
    return '/';
  }

  if (relativeFile.endsWith('/index.html')) {
    return (
      '/' +
      relativeFile.slice(
        0,
        -'index.html'.length
      )
    );
  }

  return (
    '/' +
    relativeFile
  );
};


const resolveInternalPath = (
  rawValue,
  htmlFile
) => {
  const value = stripQueryAndHash(
    rawValue
  );

  if (!value) {
    return null;
  }

  const currentRoute =
    currentRouteForFile(
      htmlFile
    );

  let pathname;

  try {
    pathname = new URL(
      value,
      `https://audit.local${currentRoute}`
    ).pathname;
  } catch {
    return null;
  }

  try {
    pathname = decodeURIComponent(
      pathname
    );
  } catch {
    return null;
  }

  return pathname;
};


const targetExists = (
  pathname
) => {
  if (pathname === '/') {
    return existsSync(
      path.join(
        distDirectory,
        'index.html'
      )
    );
  }

  const relativePath = pathname.replace(
    /^\/+/,
    ''
  );

  const directPath = path.join(
    distDirectory,
    relativePath
  );

  if (existsSync(directPath)) {
    return true;
  }

  if (
    path.extname(relativePath)
  ) {
    return false;
  }

  return existsSync(
    path.join(
      directPath,
      'index.html'
    )
  );
};


for (const htmlFile of htmlFiles) {
  const html = readFileSync(
    htmlFile,
    'utf8'
  );

  const titleCount = countMatches(
    html,
    /<title\b[^>]*>[\s\S]*?<\/title>/gi
  );

  const descriptionCount = countMatches(
    html,
    /<meta\s+name=["']description["'][^>]*>/gi
  );

  const canonicalTags = Array.from(
    html.matchAll(
      /<link\s+rel=["']canonical["'][^>]*>/gi
    ),
    (match) => match[0]
  );

  const ogTitleCount = countMatches(
    html,
    /<meta\s+property=["']og:title["'][^>]*>/gi
  );

  const ogDescriptionCount = countMatches(
    html,
    /<meta\s+property=["']og:description["'][^>]*>/gi
  );

  const ogUrlTags = Array.from(
    html.matchAll(
      /<meta\s+property=["']og:url["'][^>]*>/gi
    ),
    (match) => match[0]
  );

  const ogImageCount = countMatches(
    html,
    /<meta\s+property=["']og:image["'][^>]*>/gi
  );

  const twitterCardCount = countMatches(
    html,
    /<meta\s+name=["']twitter:card["'][^>]*>/gi
  );

  const robotsCount = countMatches(
    html,
    /<meta\s+name=["']robots["'][^>]*>/gi
  );

  const structuredDataCount = countMatches(
    html,
    /<script\s+type=["']application\/ld\+json["'][^>]*>[\s\S]*?<\/script>/gi
  );

  const mainCount = countMatches(
    html,
    /<main\b[^>]*>/gi
  );

  const h1Count = countMatches(
    html,
    /<h1\b[^>]*>/gi
  );

  if (
    !/^<!doctype html>/i.test(
      html.trimStart()
    )
  ) {
    addError(
      htmlFile,
      'doctype HTML ausente.'
    );
  }

  if (
    !/<html\b[^>]*\blang=["']pt-BR["']/i.test(
      html
    )
  ) {
    addError(
      htmlFile,
      'lang="pt-BR" ausente.'
    );
  }

  if (titleCount !== 1) {
    addError(
      htmlFile,
      `esperado 1 title; encontrado ${titleCount}.`
    );
  }

  if (descriptionCount !== 1) {
    addError(
      htmlFile,
      `esperada 1 meta description; encontradas ${descriptionCount}.`
    );
  }

  if (canonicalTags.length !== 1) {
    addError(
      htmlFile,
      `esperado 1 canonical; encontrados ${canonicalTags.length}.`
    );
  } else {
    const canonicalHref = getAttribute(
      canonicalTags[0],
      'href'
    );

    if (
      !canonicalHref?.startsWith(
        `${siteUrl}/`
      )
    ) {
      addError(
        htmlFile,
        `canonical inválido: ${canonicalHref ?? 'ausente'}.`
      );
    }
  }

  if (ogTitleCount !== 1) {
    addError(
      htmlFile,
      `esperado 1 og:title; encontrados ${ogTitleCount}.`
    );
  }

  if (ogDescriptionCount !== 1) {
    addError(
      htmlFile,
      `esperado 1 og:description; encontrados ${ogDescriptionCount}.`
    );
  }

  if (ogUrlTags.length !== 1) {
    addError(
      htmlFile,
      `esperado 1 og:url; encontrados ${ogUrlTags.length}.`
    );
  } else {
    const ogUrl = getAttribute(
      ogUrlTags[0],
      'content'
    );

    if (
      !ogUrl?.startsWith(
        `${siteUrl}/`
      )
    ) {
      addError(
        htmlFile,
        `og:url inválido: ${ogUrl ?? 'ausente'}.`
      );
    }
  }

  if (ogImageCount !== 1) {
    addError(
      htmlFile,
      `esperado 1 og:image; encontrados ${ogImageCount}.`
    );
  }

  if (twitterCardCount !== 1) {
    addError(
      htmlFile,
      `esperado 1 twitter:card; encontrados ${twitterCardCount}.`
    );
  }

  if (robotsCount !== 1) {
    addError(
      htmlFile,
      `esperada 1 meta robots; encontradas ${robotsCount}.`
    );
  }

  if (structuredDataCount !== 1) {
    addError(
      htmlFile,
      `esperado 1 JSON-LD; encontrados ${structuredDataCount}.`
    );
  }

  if (mainCount !== 1) {
    addError(
      htmlFile,
      `esperado 1 elemento main; encontrados ${mainCount}.`
    );
  }

  if (h1Count !== 1) {
    addError(
      htmlFile,
      `esperado 1 h1; encontrados ${h1Count}.`
    );
  }


  /*
   * Captura somente o atributo HTML id propriamente dito.
   * O espaço obrigatório antes de id impede falsos positivos
   * em atributos como data-docs-section-id.
   */
  const ids = Array.from(
    html.matchAll(
      /<[a-z][^>]*\sid\s*=\s*["']([^"']+)["'][^>]*>/gi
    ),
    (match) => match[1]
  );

  const duplicateIds = ids.filter(
    (id, index) => (
      ids.indexOf(id) !== index
    )
  );

  for (
    const duplicateId
    of new Set(duplicateIds)
  ) {
    addError(
      htmlFile,
      `ID duplicado: ${duplicateId}.`
    );
  }


  const imageTags = Array.from(
    html.matchAll(
      /<img\b[^>]*>/gi
    ),
    (match) => match[0]
  );

  for (const imageTag of imageTags) {
    if (
      !/\balt\s*=\s*["'][^"']*["']/i.test(
        imageTag
      )
    ) {
      addError(
        htmlFile,
        `imagem sem atributo alt: ${imageTag.slice(0, 120)}`
      );
    }
  }


  const inputTags = Array.from(
    html.matchAll(
      /<input\b[^>]*>/gi
    ),
    (match) => match[0]
  );

  for (const inputTag of inputTags) {
    const type =
      getAttribute(
        inputTag,
        'type'
      )?.toLowerCase() ?? 'text';

    if (type === 'hidden') {
      continue;
    }

    const hasAccessibleName = (
      /\baria-label\s*=\s*["'][^"']+["']/i.test(
        inputTag
      ) ||
      /\baria-labelledby\s*=\s*["'][^"']+["']/i.test(
        inputTag
      ) ||
      /\bid\s*=\s*["'][^"']+["']/i.test(
        inputTag
      )
    );

    if (!hasAccessibleName) {
      addError(
        htmlFile,
        `input sem nome acessível: ${inputTag.slice(0, 120)}`
      );
    }
  }


  const anchorTags = Array.from(
    html.matchAll(
      /<a\b[^>]*>/gi
    ),
    (match) => match[0]
  );

  for (const anchorTag of anchorTags) {
    const href = getAttribute(
      anchorTag,
      'href'
    );

    if (href === null || href.trim() === '') {
      addError(
        htmlFile,
        `link sem href válido: ${anchorTag.slice(0, 120)}`
      );

      continue;
    }

    const target = getAttribute(
      anchorTag,
      'target'
    );

    const rel = getAttribute(
      anchorTag,
      'rel'
    ) ?? '';

    if (
      target === '_blank' &&
      !/\b(?:noreferrer|noopener)\b/i.test(
        rel
      )
    ) {
      addError(
        htmlFile,
        `target="_blank" sem rel seguro: ${href}`
      );
    }

    if (
      href.startsWith('http://') &&
      !href.startsWith(
        'http://localhost'
      )
    ) {
      addError(
        htmlFile,
        `link externo sem HTTPS: ${href}`
      );
    }

    if (
      href.startsWith('#') ||
      href.startsWith('mailto:') ||
      href.startsWith('tel:') ||
      href.startsWith('javascript:') ||
      href.startsWith('data:') ||
      href.startsWith('http://') ||
      href.startsWith('https://') ||
      href.startsWith('//')
    ) {
      continue;
    }

    const pathname = resolveInternalPath(
      href,
      htmlFile
    );

    if (
      pathname &&
      !targetExists(pathname)
    ) {
      addError(
        htmlFile,
        `link interno não resolvido: ${href}`
      );
    }
  }


  const localAssetTags = Array.from(
    html.matchAll(
      /<(?:img|script|link|source)\b[^>]*(?:src|href)=["']([^"']+)["'][^>]*>/gi
    ),
    (match) => match[1]
  );

  for (const assetReference of localAssetTags) {
    if (
      assetReference.startsWith('data:') ||
      assetReference.startsWith('http://') ||
      assetReference.startsWith('https://') ||
      assetReference.startsWith('//') ||
      assetReference.startsWith('#')
    ) {
      continue;
    }

    const pathname = resolveInternalPath(
      assetReference,
      htmlFile
    );

    if (
      pathname &&
      !targetExists(pathname)
    ) {
      addError(
        htmlFile,
        `arquivo interno não encontrado: ${assetReference}`
      );
    }
  }


  if (
    html.length > 700_000
  ) {
    addWarning(
      htmlFile,
      `HTML grande: ${html.length} bytes.`
    );
  }
}


const requiredPublicFiles = [
  'robots.txt',
  'sitemap.xml',
  'site.webmanifest'
];

for (const filename of requiredPublicFiles) {
  const publicPath = path.join(
    publicDirectory,
    filename
  );

  const distPath = path.join(
    distDirectory,
    filename
  );

  if (!existsSync(publicPath)) {
    errors.push(
      `public/${filename}: arquivo ausente.`
    );
  }

  if (!existsSync(distPath)) {
    errors.push(
      `dist/${filename}: arquivo ausente após o build.`
    );
  }
}


const robotsPath = path.join(
  distDirectory,
  'robots.txt'
);

if (existsSync(robotsPath)) {
  const robots = readFileSync(
    robotsPath,
    'utf8'
  );

  if (
    !robots.includes(
      `${siteUrl}/sitemap.xml`
    )
  ) {
    errors.push(
      'dist/robots.txt: sitemap oficial ausente.'
    );
  }
}


const sitemapPath = path.join(
  distDirectory,
  'sitemap.xml'
);

if (existsSync(sitemapPath)) {
  const sitemap = readFileSync(
    sitemapPath,
    'utf8'
  );

  const sitemapUrls = Array.from(
    sitemap.matchAll(
      /<loc>([^<]+)<\/loc>/g
    ),
    (match) => match[1]
  );

  if (
    sitemapUrls.length !== htmlFiles.length
  ) {
    errors.push(
      'dist/sitemap.xml: ' +
      `${sitemapUrls.length} URL(s) para ` +
      `${htmlFiles.length} página(s) HTML.`
    );
  }

  for (const url of sitemapUrls) {
    if (!url.startsWith(`${siteUrl}/`)) {
      errors.push(
        `dist/sitemap.xml: URL inválida: ${url}`
      );
    }
  }
}


const manifestPath = path.join(
  distDirectory,
  'site.webmanifest'
);

if (existsSync(manifestPath)) {
  try {
    const manifest = JSON.parse(
      readFileSync(
        manifestPath,
        'utf8'
      )
    );

    if (manifest.name !== 'AutoM8 - Linux Management Suite') {
      errors.push(
        'dist/site.webmanifest: nome inválido.'
      );
    }

    if (
      !Array.isArray(manifest.icons) ||
      manifest.icons.length === 0
    ) {
      errors.push(
        'dist/site.webmanifest: nenhum ícone informado.'
      );
    }
  } catch (error) {
    errors.push(
      `dist/site.webmanifest: JSON inválido: ${error.message}`
    );
  }
}


if (warnings.length > 0) {
  console.log(
    '\n[AutoM8] Avisos da auditoria:'
  );

  for (const warning of warnings) {
    console.log(
      `- ${warning}`
    );
  }
}


if (errors.length > 0) {
  console.error(
    '\n[AutoM8] Auditoria do website reprovada:'
  );

  for (const error of errors) {
    console.error(
      `- ${error}`
    );
  }

  process.exit(1);
}


console.log(
  `[AutoM8] Auditoria SEO, acessibilidade e links aprovada: ${htmlFiles.length} página(s).`
);
