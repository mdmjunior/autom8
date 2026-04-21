<?php

namespace App\Services\Autom8\Build;

use App\DTO\BuildSelectionData;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;
use RuntimeException;

class ScriptBuilder
{
    public function build(BuildSelectionData $selection, array $resolvedSelection): array
    {
        $buildUuid = (string) Str::uuid();
        $basePath = storage_path("app/autom8/builds/{$buildUuid}");

        if (! File::exists($basePath)) {
            File::makeDirectory($basePath, 0755, true);
        }

        $manifestPath = $basePath . '/manifest.json';
        $installPath = $basePath . '/install.sh';
        $functionsPath = $basePath . '/functions.sh';
        $checksPath = $basePath . '/checks.sh';

        File::put($installPath, $this->buildInstallScript($selection, $resolvedSelection));
        File::put($functionsPath, $this->buildFunctionsScript());
        File::put($checksPath, $this->buildChecksScript());

        chmod($installPath, 0755);
        chmod($functionsPath, 0755);
        chmod($checksPath, 0755);

        return [
            'build_uuid' => $buildUuid,
            'base_path' => $basePath,
            'manifest_path' => $manifestPath,
            'install_path' => $installPath,
            'functions_path' => $functionsPath,
            'checks_path' => $checksPath,
        ];
    }

    public function writeManifest(string $manifestPath, array $manifest): void
    {
        $json = json_encode($manifest, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

        if ($json === false) {
            throw new RuntimeException('Failed to encode manifest JSON.');
        }

        File::put($manifestPath, $json . PHP_EOL);
    }

    protected function buildInstallScript(BuildSelectionData $selection, array $resolvedSelection): string
    {
        $distroSlug = $selection->distroSlug;
        $packageBlocks = [];
        $actionBlocks = [];

        foreach ($resolvedSelection['packages'] ?? [] as $package) {
            $commands = [];

            if (! empty($package['variant']['repository_setup_command'])) {
                $commands[] = trim($package['variant']['repository_setup_command']);
            }

            if (! empty($package['variant']['pre_install_command'])) {
                $commands[] = trim($package['variant']['pre_install_command']);
            }

            if (! empty($package['variant']['install_command'])) {
                $commands[] = trim($package['variant']['install_command']);
            }

            if (! empty($package['variant']['post_install_command'])) {
                $commands[] = trim($package['variant']['post_install_command']);
            }

            if (empty($commands)) {
                continue;
            }

            $packageBlocks[] = $this->wrapSection(
                "Installing package: {$package['name']} ({$package['slug']})",
                implode("\n\n", $commands)
            );
        }

        foreach ($resolvedSelection['actions'] ?? [] as $action) {
            $template = trim((string) ($action['script_template'] ?? ''));

            if ($template === '') {
                continue;
            }

            $rendered = $this->renderActionTemplate($template, $action['input_value']);

            $actionBlocks[] = $this->wrapSection(
                "Applying system action: {$action['name']} ({$action['slug']})",
                $rendered
            );
        }

        $bodySections = array_filter([
            $this->buildHeaderComment($selection, $resolvedSelection),
            $this->wrapSection('Pre-flight checks', 'run_preflight_checks'),
            ...$packageBlocks,
            ...$actionBlocks,
            $this->wrapSection('Final summary', 'print_summary'),
        ]);

        $body = implode("\n\n", $bodySections);

        return <<<BASH
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
source "\${SCRIPT_DIR}/functions.sh"
source "\${SCRIPT_DIR}/checks.sh"

TARGET_DISTRO="{$distroSlug}"

main() {
  print_banner
  ensure_sudo
  detect_distro "\${TARGET_DISTRO}"

{$this->indentBlock($body, 2)}
}

main "\$@"
BASH;
    }

    protected function buildFunctionsScript(): string
    {
        return <<<'BASH'
#!/usr/bin/env bash

print_banner() {
  echo "========================================"
  echo " AutoM8 - Linux Post-Install Package"
  echo "========================================"
  echo
}

log_info() {
  echo "[INFO] $1"
}

log_warn() {
  echo "[WARN] $1"
}

log_error() {
  echo "[ERROR] $1" >&2
}

print_summary() {
  echo
  echo "AutoM8 execution finished."
  echo "Review warnings above, if any."
}
BASH;
    }

    protected function buildChecksScript(): string
    {
        return <<<'BASH'
#!/usr/bin/env bash

ensure_sudo() {
  if [[ "${EUID}" -ne 0 ]]; then
    log_error "Please run this script with sudo."
    exit 1
  fi
}

detect_distro() {
  local expected_distro="${1:-}"

  if [[ ! -f /etc/os-release ]]; then
    log_error "/etc/os-release not found. Unable to detect distro."
    exit 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  if [[ -z "${ID:-}" ]]; then
    log_error "Unable to detect distro ID from /etc/os-release."
    exit 1
  fi

  if [[ -n "${expected_distro}" && "${ID}" != "${expected_distro}" ]]; then
    log_error "This package was generated for '${expected_distro}', but current distro is '${ID}'."
    exit 1
  fi

  log_info "Detected distro: ${ID}"
}

run_preflight_checks() {
  log_info "Running pre-flight checks..."

  if ! command -v bash >/dev/null 2>&1; then
    log_error "bash is required."
    exit 1
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    log_error "sudo is required."
    exit 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    log_warn "curl is not installed. Some package installation steps may fail."
  fi
}
BASH;
    }

    protected function renderActionTemplate(string $template, mixed $value): string
    {
        $replacement = '';

        if (is_bool($value)) {
            $replacement = $value ? 'true' : 'false';
        } elseif ($value !== null) {
            $replacement = str_replace('"', '\"', (string) $value);
        }

        return str_replace('{{ value }}', $replacement, $template);
    }

    protected function wrapSection(string $title, string $body): string
    {
        $body = trim($body);

        if ($body === '') {
            return '';
        }

        return <<<BASH
  log_info "{$title}"
{$this->indentBlock($body, 2)}
BASH;
    }

    protected function buildHeaderComment(BuildSelectionData $selection, array $resolvedSelection): string
    {
        $packageCount = count($resolvedSelection['packages'] ?? []);
        $actionCount = count($resolvedSelection['actions'] ?? []);

        return <<<BASH
  # AutoM8 generated script
  # Target distro: {$selection->distroSlug}
  # Packages: {$packageCount}
  # Actions: {$actionCount}
BASH;
    }

    protected function indentBlock(string $content, int $spaces = 2): string
    {
        $indent = str_repeat(' ', $spaces);

        return collect(explode("\n", $content))
            ->map(fn(string $line) => $line === '' ? '' : $indent . $line)
            ->implode("\n");
    }
}
