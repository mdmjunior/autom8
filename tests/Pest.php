<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/*
|--------------------------------------------------------------------------
| Test Case
|--------------------------------------------------------------------------
|
| The closure you provide to your test functions is always bound to a specific PHPUnit test
| case class. By default, that class is "PHPUnit\Framework\TestCase". Of course, you may
| need to change it using the "pest()" function to bind different classes or traits.
|
*/

pest()->extend(TestCase::class)
    // ->use(RefreshDatabase::class)
    ->in('Feature');

/*
|--------------------------------------------------------------------------
| Expectations
|--------------------------------------------------------------------------
|
| When you're writing tests, you often need to check that values meet certain conditions. The
| "expect()" function gives you access to a set of "expectations" methods that you can use
| to assert different things. Of course, you may extend the Expectation API at any time.
|
*/

expect()->extend('toBeOne', function () {
    return $this->toBe(1);
});

/*
|--------------------------------------------------------------------------
| Functions
|--------------------------------------------------------------------------
|
| While Pest is very powerful out-of-the-box, you may have some testing code specific to your
| project that you don't want to repeat in every file. Here you can also expose helpers as
| global functions to help you to reduce the number of lines of code in your test files.
|
*/

function something()
{
    // ..
}

use Illuminate\Support\Facades\DB;

if (! function_exists('validPackageInstallMethod')) {
    function validPackageInstallMethod(): string
    {
        $row = DB::selectOne("
            select sql
            from sqlite_master
            where type = 'table'
              and name = 'packages'
        ");

        $sql = $row->sql ?? '';

        if (preg_match('/install_method[^,]*check\s*\(\s*["`]?install_method["`]?\s+in\s*\(([^)]*)\)\s*\)/i', $sql, $matches)) {
            $values = array_map(
                static fn($value) => trim($value, " \t\n\r\0\x0B'\""),
                explode(',', $matches[1])
            );

            $values = array_values(array_filter($values));

            if ($values !== []) {
                return $values[0];
            }
        }

        return 'apt';
    }
}
