#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"

./scripts/package.sh
cp installer/install.sh site/public/install.sh
chmod +x site/public/install.sh

cd "$PROJECT_ROOT/site"

npm install
npm run build

echo "Site build concluído."
