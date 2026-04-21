<?php

namespace App\Services\Autom8\Catalog;

use RuntimeException;
use Symfony\Component\Yaml\Yaml;

class CatalogReader
{
    public function __construct(
        protected ?string $catalogPath = null
    ) {
        $this->catalogPath = $catalogPath ?: base_path('catalog');
    }

    public function readAll(): array
    {
        return [
            'distros' => $this->readDistros(),
            'packages' => $this->readPackages(),
            'profiles' => $this->readProfiles(),
            'system_actions' => $this->readSystemActions(),
        ];
    }

    public function readDistros(): array
    {
        $data = $this->readYamlFile('distros.yaml');

        return $data['distros'] ?? [];
    }

    public function readPackages(): array
    {
        $data = $this->readYamlFile('packages.yaml');

        return $data['packages'] ?? [];
    }

    public function readProfiles(): array
    {
        $data = $this->readYamlFile('profiles.yaml');

        return $data['profiles'] ?? [];
    }

    public function readSystemActions(): array
    {
        $data = $this->readYamlFile('system-actions.yaml');

        return $data['system_actions'] ?? [];
    }

    protected function readYamlFile(string $fileName): array
    {
        $fullPath = $this->catalogPath . DIRECTORY_SEPARATOR . $fileName;

        if (! file_exists($fullPath)) {
            throw new RuntimeException("Catalog file not found: {$fullPath}");
        }

        $parsed = Yaml::parseFile($fullPath);

        if (! is_array($parsed)) {
            throw new RuntimeException("Invalid YAML structure in file: {$fullPath}");
        }

        return $parsed;
    }
}
