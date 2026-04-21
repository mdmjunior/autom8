<?php

namespace App\Services\Autom8\Build;

use RuntimeException;

class ChecksumService
{
    public function sha256(string $filePath): string
    {
        if (! is_file($filePath)) {
            throw new RuntimeException("File not found for checksum generation: {$filePath}");
        }

        $hash = hash_file('sha256', $filePath);

        if ($hash === false) {
            throw new RuntimeException("Failed to generate SHA-256 for file: {$filePath}");
        }

        return $hash;
    }
}
