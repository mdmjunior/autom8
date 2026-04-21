<?php

namespace App\Services\Autom8\Build;

use Illuminate\Support\Facades\File;
use RuntimeException;
use ZipArchive;

class ZipBuilder
{
    public function build(string $sourceDirectory, string $zipFilePath): string
    {
        if (! File::exists($sourceDirectory) || ! File::isDirectory($sourceDirectory)) {
            throw new RuntimeException("Source directory for ZIP does not exist: {$sourceDirectory}");
        }

        $zipDirectory = dirname($zipFilePath);

        if (! File::exists($zipDirectory)) {
            File::makeDirectory($zipDirectory, 0755, true);
        }

        $zip = new ZipArchive();

        if ($zip->open($zipFilePath, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) {
            throw new RuntimeException("Unable to create ZIP file: {$zipFilePath}");
        }

        $files = File::allFiles($sourceDirectory);

        foreach ($files as $file) {
            $absolutePath = $file->getRealPath();
            $relativePath = ltrim(str_replace($sourceDirectory, '', $absolutePath), DIRECTORY_SEPARATOR);

            if (! $absolutePath || ! is_file($absolutePath)) {
                continue;
            }

            $zip->addFile($absolutePath, $relativePath);
        }

        $zip->close();

        if (! File::exists($zipFilePath)) {
            throw new RuntimeException("ZIP file was not created: {$zipFilePath}");
        }

        return $zipFilePath;
    }
}
