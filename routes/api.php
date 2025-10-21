<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Middleware\VerifySupabaseJwt;

// Public routes
Route::get('/health', fn() => response()->json(['ok' => true]));
Route::post('/register', function (Request $request) {
    return response()->json(['ok' => true, 'saw' => $request->only('name', 'email')], 201);
});
Route::post('/login', function (Request $request) {
    return response()->json(['ok' => true, 'saw' => $request->only('email')]);
});

// Protected routes (require Supabase JWT)
Route::middleware([VerifySupabaseJwt::class])->group(function () {
    Route::get('/me', function (Request $request) {
        return response()->json([
            'userId' => $request->attributes->get('supabase_user_id'),
            'claims' => $request->attributes->get('supabase_claims'),
        ]);
    });
});

// Debug helper
Route::get('/__routes', function () {
    return collect(Route::getRoutes())
        ->map(fn($r) => ['method' => implode('|', $r->methods()), 'uri' => $r->uri()])
        ->filter(fn($r) => str_starts_with($r['uri'], 'api/'))
        ->values();
});

Route::get('/ping', fn() => response()->json(['pong' => true, 'ts' => now()->toIso8601String()]));

