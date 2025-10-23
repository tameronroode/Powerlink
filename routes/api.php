<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Middleware\VerifySupabaseJwt;
use App\Http\Controllers\Auth\EmployeeController; // Make sure namespace matches your folder

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| These routes are loaded by the RouteServiceProvider within a group
| assigned the "api" middleware group. Here we only include Supabase
| JWT-protected routes and simple public routes.
|
*/

// Public test routes
Route::get('/health', fn() => response()->json(['ok' => true]));
Route::get('/ping', fn() => response()->json([
    'pong' => true,
    'ts' => now()->toIso8601String()
]));

// Example registration/login placeholders
Route::post('/register', function (Request $request) {
    return response()->json([
        'ok' => true,
        'saw' => $request->only('name', 'email')
    ], 201);
});

Route::post('/login', function (Request $request) {
    return response()->json([
        'ok' => true,
        'saw' => $request->only('email')
    ]);
});

// Protected routes using Supabase JWT middleware
Route::middleware([VerifySupabaseJwt::class])->group(function () {
    // Current authenticated user info
    Route::get('/me', function (Request $request) {
        return response()->json([
            'userId' => $request->attributes->get('supabase_user_id'),
            'claims' => $request->attributes->get('supabase_claims'),
        ]);
    });

    // Employee API routes
    Route::get('/employees', [EmployeeController::class, 'index']);
    Route::get('/employees/{id}', [EmployeeController::class, 'show']);
    Route::post('/employees', [EmployeeController::class, 'store']);
    Route::put('/employees/{id}', [EmployeeController::class, 'update']);
    Route::delete('/employees/{id}', [EmployeeController::class, 'destroy']);
});

// Debug helper route
Route::get('/__routes', function () {
    return collect(Route::getRoutes())
        ->map(fn($r) => ['method' => implode('|', $r->methods()), 'uri' => $r->uri()])
        ->filter(fn($r) => str_starts_with($r['uri'], 'api/'))
        ->values();
});
