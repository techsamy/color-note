<?php

declare(strict_types=1);

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Web\DeleteAccountRequest;
use App\Services\AccountService;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;

final class DeleteAccountController extends Controller
{
    public function show(): View
    {
        return view('site.delete-account');
    }

    public function destroy(DeleteAccountRequest $request, AccountService $accounts): View|RedirectResponse
    {
        $user = $accounts->findByCredentials(
            $request->string('email')->toString(),
            $request->string('password')->toString(),
        );
        if ($user === null) {
            // Same message for unknown email / wrong password / Google-only account.
            return back()
                ->withInput($request->only('email'))
                ->withErrors(['password' => 'That email and password don\'t match an account.']);
        }

        $accounts->delete($user);

        return view('site.delete-account-done');
    }
}
