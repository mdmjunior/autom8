<?php

test('dashboard redirects to autom8 landing', function () {
    $response = $this->get('/dashboard');

    $response->assertRedirect('/projetos/autom8');
});
