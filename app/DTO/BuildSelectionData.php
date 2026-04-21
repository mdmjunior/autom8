<?php

namespace App\DTO;

class BuildSelectionData
{
    public function __construct(
        public readonly string $distroSlug,
        public readonly array $selectedProfileSlugs = [],
        public readonly array $selectedPackageSlugs = [],
        public readonly array $selectedActionSlugs = [],
        public readonly array $actionInputs = [],
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            distroSlug: (string) ($data['distro_slug'] ?? ''),
            selectedProfileSlugs: array_values(array_unique($data['selected_profile_slugs'] ?? [])),
            selectedPackageSlugs: array_values(array_unique($data['selected_package_slugs'] ?? [])),
            selectedActionSlugs: array_values(array_unique($data['selected_action_slugs'] ?? [])),
            actionInputs: $data['action_inputs'] ?? [],
        );
    }

    public function toArray(): array
    {
        return [
            'distro_slug' => $this->distroSlug,
            'selected_profile_slugs' => $this->selectedProfileSlugs,
            'selected_package_slugs' => $this->selectedPackageSlugs,
            'selected_action_slugs' => $this->selectedActionSlugs,
            'action_inputs' => $this->actionInputs,
        ];
    }
}
