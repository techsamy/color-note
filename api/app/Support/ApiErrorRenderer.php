<?php

declare(strict_types=1);

namespace App\Support;

use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable;

/**
 * Renders every API error as: { "error": { "code", "message", "fields"? } }
 * Contract: docs/05-api-spec.md §1.
 */
final class ApiErrorRenderer
{
    public function __invoke(Throwable $e, Request $request): ?JsonResponse
    {
        if (! $request->is('api/*')) {
            return null; // let Laravel handle non-API routes
        }

        return match (true) {
            $e instanceof ValidationException => $this->error(422, 'VALIDATION_FAILED', 'The given data was invalid.', $e->errors()),
            $e instanceof AuthenticationException => $this->error(401, 'UNAUTHENTICATED', 'Unauthenticated.'),
            $e instanceof AuthorizationException,
            $e instanceof AccessDeniedHttpException => $this->error(403, 'FORBIDDEN', 'This action is unauthorized.'),
            $e instanceof ModelNotFoundException,
            $e instanceof NotFoundHttpException => $this->error(404, 'NOT_FOUND', 'Resource not found.'),
            $e instanceof HttpExceptionInterface => $this->fromHttpException($e),
            default => $this->error(
                500,
                'SERVER_ERROR',
                config('app.debug') ? $e->getMessage() : 'Server error.',
            ),
        };
    }

    private function fromHttpException(HttpExceptionInterface $e): JsonResponse
    {
        $status = $e->getStatusCode();
        $code = match ($status) {
            400 => 'BAD_REQUEST',
            405 => 'METHOD_NOT_ALLOWED',
            409 => 'CONFLICT',
            426 => 'APP_UPGRADE_REQUIRED',
            429 => 'RATE_LIMITED',
            default => $status >= 500 ? 'SERVER_ERROR' : 'HTTP_ERROR',
        };

        $message = $e->getMessage() !== '' ? $e->getMessage() : (string) (Response::$statusTexts[$status] ?? 'Error');

        return $this->error($status, $code, $message, headers: $e->getHeaders());
    }

    /**
     * @param  array<string, array<int, string>>|null  $fields
     * @param  array<string, string>  $headers
     */
    private function error(int $status, string $code, string $message, ?array $fields = null, array $headers = []): JsonResponse
    {
        $body = ['code' => $code, 'message' => $message];
        if ($fields !== null) {
            $body['fields'] = $fields;
        }

        return response()->json(['error' => $body], $status, $headers);
    }
}
