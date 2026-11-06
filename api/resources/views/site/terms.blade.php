@extends('site.layout')

@php
    $appName = config('app.name');
    $site = config('huenote.site');
    $email = $site['support_email'];
@endphp

@section('title', 'Terms of use')
@section('description', 'The terms for using '.$appName.', a free notes app.')
@section('header-class', 'solid')

@section('content')
<div class="wrap">
    <header class="page-head">
        <h1>Terms of use</h1>
        <p>Last updated: {{ $site['legal_updated'] }}</p>
    </header>

    <article class="prose">
        <p>These terms apply when you use the {{ $appName }} app, its optional account and sync service, and this website. They are written to be read. By using {{ $appName }} you agree to them; if you don't agree, please don't use it.</p>

        <h2>1. The service</h2>
        <p>{{ $appName }} is a free notes and checklist app. It works fully on your phone without an account. If you create an account, we also store your notes on our servers so you can sync and restore them. There are no ads and no paid tiers. We may add, change or remove features over time; if we ever have to stop the sync service, we will give you reasonable notice so you can export your notes.</p>

        <h2>2. Your account</h2>
        <ul>
            <li>You must give a real email address and keep your password safe. You are responsible for what happens in your account.</li>
            <li>Accounts are for people aged 18 or over, or younger people with the consent of a parent or guardian.</li>
            <li>One person per account. Don't create accounts by automated means.</li>
            <li>You can delete your account at any time from the app or on our <a href="{{ route('site.delete-account') }}">delete-account page</a>.</li>
        </ul>

        <h2>3. Your notes belong to you</h2>
        <p>You keep all rights to everything you write in {{ $appName }}. You give us only the permission needed to store, sync and show your notes back to you (and, if you use note sharing in future, to the people you share with). We do not read, sell or use your notes for anything else. Our <a href="{{ route('site.privacy') }}">privacy policy</a> explains how we handle data.</p>

        <h2>4. Master password and recovery key</h2>
        <p>Locked notes are encrypted on your device. We never have your master password or recovery key, so <strong>if you lose both, we cannot unlock your locked notes</strong> — nobody can. Please keep your recovery key somewhere safe.</p>

        <h2>5. Fair use</h2>
        <p>Please don't use {{ $appName }} to break the law, to store or spread illegal content, to attack, overload or probe our servers, to get around rate limits or security, or to access anyone else's account. We may suspend or close accounts that do this, after telling you why where the law allows.</p>

        <h2>6. Keep your own backups</h2>
        <p>We work hard never to lose data — notes are saved instantly, deleted notes go to the trash first, and conflicting edits are kept as copies instead of being overwritten. Still, phones get lost and software has bugs. Keep a backup of anything important (<em>Settings → Backup &amp; restore</em>).</p>

        <h2>7. No warranty</h2>
        <p>{{ $appName }} is provided free and "as is". To the extent the law allows, we make no promises that it will always be available, error-free or fit for a particular purpose.</p>

        <h2>8. Limitation of liability</h2>
        <p>To the extent the law allows, we are not liable for indirect or consequential losses, or for loss of data, arising from your use of {{ $appName }}. Nothing in these terms limits liability that cannot be limited by law, or your rights as a consumer.</p>

        <h2>9. Changes to these terms</h2>
        <p>We may update these terms. We will change the date at the top and, for important changes, tell you in the app beforehand. If you keep using {{ $appName }} after a change, the new terms apply.</p>

        <h2>10. Law and disputes</h2>
        <p>These terms are governed by the laws of {{ $site['country'] }}, and the courts of {{ $site['country'] }} have jurisdiction. Before going to court, please write to us — most things can be sorted out with an email.</p>

        <h2>11. Contact</h2>
        <p><a href="mailto:{{ $email }}">{{ $email }}</a>{{ $site['publisher'] !== '' ? ' · '.$site['publisher'] : '' }}</p>
    </article>
</div>
@endsection
