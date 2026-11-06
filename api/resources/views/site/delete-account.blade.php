@extends('site.layout')

@php
    $appName = config('app.name');
    $email = config('huenote.site.support_email');
@endphp

@section('title', 'Delete your account')
@section('description', 'Delete your '.$appName.' account and all data stored on our servers.')
@section('header-class', 'solid')

@section('content')
<div class="wrap">
    <header class="page-head">
        <h1>Delete your {{ $appName }} account</h1>
        <p>You can delete your account and everything stored with it on our servers — in the app or right here.</p>
    </header>

    <div class="two-col prose" style="max-width:none">
        <div>
            <h2 style="margin-top:.6em">In the app</h2>
            <ol class="steps">
                <li>Open {{ $appName }} and go to <strong>Settings</strong>.</li>
                <li>Tap <strong>Account &amp; sync</strong>.</li>
                <li>Tap <strong>Delete account</strong> and confirm with your password.</li>
            </ol>

            <h2>What gets deleted</h2>
            <ul>
                <li>Your account: email, name, password hash and Google link.</li>
                <li>Every note, checklist and colour label stored on our servers — including locked notes.</li>
                <li>Your device list, sign-in tokens (all devices are signed out) and master-key data.</li>
            </ul>
            <p>This happens <strong>immediately</strong> and can't be undone. Copies in server backups, if any, are overwritten within 30 days. Notes already on your phone are not touched — they stay there as offline notes until you delete them or uninstall the app.</p>

            <h2>Signed up with Google?</h2>
            <p>Delete it in the app (you confirm with Google there), or email <a href="mailto:{{ $email }}?subject={{ rawurlencode('Delete my '.$appName.' account') }}">{{ $email }}</a> from the Gmail address of your account with the subject "Delete my account". We'll delete it within 7 days and confirm by email.</p>
        </div>

        <div>
            <form class="form-card" method="post" action="{{ route('site.delete-account.submit') }}" novalidate>
                @csrf
                <h2 style="margin-top:0;font-size:1.35rem">Delete here</h2>
                <p style="color:var(--muted)">For accounts with an email and password.</p>

                @if ($errors->any())
                    <div class="alert" role="alert">{{ $errors->first('password') ?: 'Please check the form.' }}</div>
                @endif

                <div class="field">
                    <label for="email">Email</label>
                    <input id="email" name="email" type="email" autocomplete="email" required value="{{ old('email') }}" @error('email') aria-invalid="true" aria-describedby="email-error" @enderror>
                    @error('email')<div class="error" id="email-error">{{ $message }}</div>@enderror
                </div>
                <div class="field">
                    <label for="password">Password</label>
                    <input id="password" name="password" type="password" autocomplete="current-password" required>
                </div>
                <div class="field">
                    <label class="check"><input type="checkbox" name="confirm" value="1" @checked(old('confirm'))> I understand that my account and all notes stored on the server will be permanently deleted.</label>
                    @error('confirm')<div class="error">{{ $message }}</div>@enderror
                </div>
                <button class="btn btn-danger" type="submit">@include('site.partials.icon', ['name' => 'delete']) Delete my account</button>
            </form>
        </div>
    </div>
</div>
@endsection
