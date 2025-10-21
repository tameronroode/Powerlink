<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;
use GuzzleHttp\Client;

class VerifySupabaseJwt
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json(['message' => 'Missing bearer token'], 401);
        }

        try {
            // Fetch JWKS (cache for 1 hour)
            $jwks = Cache::remember('supabase_jwks', 3600, function () {
                $base = rtrim(config('services.supabase.url'), '/');
                $jwksUrl = config('services.supabase.jwks_url') ?? $base . '/auth/v1/.well-known/jwks.json';
                $json = file_get_contents($jwksUrl);
                return json_decode($json, true);
            });

            // Decode and verify the JWT
            $decoded = JWT::decode($token, JWK::parseKeySet($jwks));

            // Optional: verify issuer matches your Supabase project
            $iss = rtrim(config('services.supabase.url'), '/') . '/auth/v1';
            if (($decoded->iss ?? '') !== $iss) {
                return response()->json(['message' => 'Invalid issuer'], 401);
            }

            // Attach user info for later use
            $request->attributes->set('supabase_user_id', $decoded->sub ?? null);
            $request->attributes->set('supabase_claims', (array) $decoded);

        } catch (\Throwable $e) {
            return response()->json(['message' => 'Invalid token', 'error' => $e->getMessage()], 401);
        }

        return $next($request);
    }
}
