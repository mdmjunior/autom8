<?php

namespace App\Services\Autom8\Support;

use DateTimeZone;

class TimezoneValidator
{
    public function isValid(?string $timezone, array $allowed = []): bool
    {
        if (! is_string($timezone) || trim($timezone) === '') {
            return false;
        }

        $timezone = trim($timezone);

        if (! empty($allowed) && ! in_array($timezone, $allowed, true)) {
            return false;
        }

        return in_array($timezone, DateTimeZone::listIdentifiers(), true);
    }

    public function normalize(?string $timezone): string
    {
        return trim((string) $timezone);
    }
}
