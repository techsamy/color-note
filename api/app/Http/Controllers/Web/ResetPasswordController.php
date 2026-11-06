<?php

declare(strict_types=1);

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Web\ResetPasswordRequest;
use App\Services\AccountService;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

final class ResetPasswordController extends Controller
{
    public function show(Request $request): View
    {
        return view('site.reset-password', [
            'token' => $request->string('token')->toString(),
            'email' => $request->string('email')->toString(),
        ]);
    }

    public function update(ResetPasswordRequest $request, AccountService $accounts): View|RedirectResponse
    {
        $ok = $accounts->resetPassword(
            $request->string('email')->toString(),
            $request->string('token')->toString(),
            $request->string('password')->toString(),
        );
        if (! $ok) {
            return back()
                ->withInput($request->only('email', 'token'))
                ->withErrors(['token' => 'This reset link is invalid or has expired. Ask for a new one in the app.']);
        }

        return view('site.reset-password-done');
    }
}
