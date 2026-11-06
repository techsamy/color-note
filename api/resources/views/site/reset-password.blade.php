@extends('site.layout')

@section('title', 'Choose a new password')
@section('noindex', true)
@section('header-class', 'solid')

@section('content')
<div class="wrap" style="padding:56px 20px 72px">
    <form class="form-card" style="margin:0 auto" method="post" action="{{ route('site.reset-password.submit') }}" novalidate>
        @csrf
        <h1 style="font-size:1.8rem">Choose a new password</h1>
        <p style="color:var(--muted)">for your {{ config('app.name') }} account.</p>

        @if ($token === '' && old('token') === null)
            <div class="alert" role="alert">This link is incomplete. Open the link from the email again, or ask for a new one in the app (Sign in → Forgot password?).</div>
        @endif
        @error('token')<div class="alert" role="alert">{{ $message }}</div>@enderror

        <input type="hidden" name="token" value="{{ old('token', $token) }}">
        <div class="field">
            <label for="email">Email</label>
            <input id="email" name="email" type="email" autocomplete="username" required value="{{ old('email', $email) }}">
            @error('email')<div class="error">{{ $message }}</div>@enderror
        </div>
        <div class="field">
            <label for="password">New password</label>
            <input id="password" name="password" type="password" autocomplete="new-password" minlength="8" required>
            <div class="hint">At least 8 characters.</div>
            @error('password')<div class="error">{{ $message }}</div>@enderror
        </div>
        <div class="field">
            <label for="password_confirmation">Repeat new password</label>
            <input id="password_confirmation" name="password_confirmation" type="password" autocomplete="new-password" required>
        </div>
        <button class="btn btn-primary" type="submit">Save new password</button>
        <p class="hint" style="color:var(--muted);font-size:.9rem;margin:16px 0 0">This changes your account password only. Your master password for locked notes stays the same.</p>
    </form>
</div>
@endsection
