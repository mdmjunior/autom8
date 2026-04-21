# Release Guide

## Branch model

- `develop`: integração e ambiente de desenvolvimento
- `main`: releases e ambiente de produção

## Current release

- `v1.0.0`

## Release flow

### 1. Synchronize the latest work

Bring the most recent code into your local environment before preparing a release.

### 2. Validate locally

Run the application checks locally:

- tests
- frontend build
- general review of changed files

### 3. Update release docs

Before releasing, confirm:

- `README.md`
- `CHANGELOG.md`
- workflow files
- deployment files

### 4. Push to develop

All integration work should be committed and pushed to `develop`.

### 5. Merge develop into main

When the release is ready, merge `develop` into `main`.

### 6. Tag the release

Create and push a version tag.

Example:

```bash
git tag -a v1.0.0 -m "AutoM8 v1.0.0"
git push origin v1.0.0
```

### 7. Deploy environments

Development

- branch: develop

Production

- branch: main
