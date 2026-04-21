<?php

namespace App\Services\Autom8\Support;

class HostnameSanitizer
{
    public function isValid(?string $hostname): bool
    {
        if (! is_string($hostname)) {
            return false;
        }

        $hostname = trim($hostname);

        if ($hostname === '') {
            return false;
        }

        if (strlen($hostname) > 63) {
            return false;
        }

        return (bool) preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?$/', $hostname);
    }

    public function normalize(?string $hostname): string
    {
        return trim((string) $hostname);
    }
}
