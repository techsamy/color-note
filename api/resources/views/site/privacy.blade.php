@extends('site.layout')

@php
    $appName = config('app.name');
    $site = config('huenote.site');
    $email = $site['support_email'];
    $publisher = $site['publisher'];
@endphp

@section('title', 'Privacy policy')
@section('description', 'How '.$appName.' handles your data: no ads, no tracking, offline by default, and locked notes encrypted on your phone.')
@section('header-class', 'solid')

@section('content')
<div class="wrap">
    <header class="page-head">
        <h1>Privacy policy</h1>
        <p>Last updated: {{ $site['legal_updated'] }}</p>
    </header>

    <article class="prose">
        <div class="callout bg-green" style="color:var(--n-ink)">
            <p><strong>The short version.</strong> {{ $appName }} has no ads, no trackers and no analytics. If you never create an account, your notes never leave your phone and we receive nothing at all. If you do create an account, we store what is needed to sync your notes — and notes you lock with your master password are encrypted on your phone, so we can't read them.</p>
        </div>

        <nav class="toc" aria-label="Contents">
            <ol>
                <li><a href="#who">Who we are</a></li>
                <li><a href="#without-account">Using the app without an account</a></li>
                <li><a href="#with-account">If you create an account</a></li>
                <li><a href="#locked">Locked notes</a></li>
                <li><a href="#not-collected">What we never collect</a></li>
                <li><a href="#sharing">Who else sees your data</a></li>
                <li><a href="#retention">How long we keep data</a></li>
                <li><a href="#rights">Your rights and choices</a></li>
                <li><a href="#security">Security</a></li>
                <li><a href="#children">Children</a></li>
                <li><a href="#website">This website</a></li>
                <li><a href="#changes">Changes and contact</a></li>
            </ol>
        </nav>

        <h2 id="who">1. Who we are</h2>
        <p>{{ $appName }} is a free notes app for Android{{ $publisher !== '' ? ' made by '.$publisher : '' }}, based in {{ $site['country'] }}. In this policy "we" and "us" mean the {{ $appName }} team, and "you" means anyone using the app or this website. Under India's Digital Personal Data Protection Act, 2023 we are the <em>data fiduciary</em> for the personal data described here. We also follow the principles of the EU GDPR for users outside India.</p>
        <p>Questions about privacy: <a href="mailto:{{ $email }}">{{ $email }}</a>.</p>

        <h2 id="without-account">2. Using the app without an account</h2>
        <p>An account is optional. Without one:</p>
        <ul>
            <li>Your notes, checklists, colours, labels and settings are stored <strong>only on your phone</strong>, in the app's private storage.</li>
            <li>The app does not connect to our servers at all, so we receive no data — not even an anonymous usage count.</li>
            <li>Backup and export files are created only when you ask, and saved wherever you choose. We never see them. Backup files are encrypted with a password you pick.</li>
        </ul>

        <h2 id="with-account">3. If you create an account</h2>
        <p>Signing in lets you sync notes between devices and restore them on a new phone. To do that we store:</p>
        <table>
            <thead><tr><th>Data</th><th>Why</th></tr></thead>
            <tbody>
                <tr><td>Email address and (optional) name</td><td>To identify your account, let you sign in and send password-reset emails.</td></tr>
                <tr><td>Password — stored only as a one-way hash (bcrypt)</td><td>To check it's you when you sign in. We can't see your actual password.</td></tr>
                <tr><td>Google account ID and email, if you sign in with Google</td><td>To link your Google sign-in to your account.</td></tr>
                <tr><td>Your notes: title, text or checklist items, colour, pinned / archived / trashed state, reminders and the times they were created and changed</td><td>To sync them to your other devices. This is the core of the service.</td></tr>
                <tr><td>Colour label names (e.g. "Work")</td><td>To sync your labels.</td></tr>
                <tr><td>Device list: a random device ID, device name, platform (e.g. Android), app version and when it last synced</td><td>So you can see and sign out your devices, and so we can keep old app versions working.</td></tr>
                <tr><td>Your encrypted master-key data (see <a href="#locked">Locked notes</a>)</td><td>So the same master password unlocks your locked notes on every device.</td></tr>
            </tbody>
        </table>
        <p>Ordinary (unlocked) notes are encrypted in transit (HTTPS) and protected on our servers, but they are not end-to-end encrypted. If you want a note to be unreadable even to us, lock it.</p>
        <p>Our servers also briefly handle your IP address to protect the service — for example to limit repeated sign-in attempts. We never log the content of your notes, your passwords or your sign-in tokens.</p>
        <p><strong>Legal basis:</strong> your consent when you create an account, and what is necessary to provide the service you asked for. You can withdraw consent at any time by deleting your account.</p>

        <h2 id="locked">4. Locked notes</h2>
        <p>When you lock a note, the app encrypts it <strong>on your phone</strong> with AES-256-GCM, using a key protected by your master password (stretched with Argon2id) and a separate recovery key. Only the encrypted result is ever synced. We never receive your master password, your recovery key or the decrypted note, so we cannot read locked notes, and we cannot recover them if you forget both your master password and your recovery key. Locked notes are also left out of search and plain-text exports.</p>

        <h2 id="not-collected">5. What we never collect</h2>
        <ul>
            <li>No advertising IDs, no ads, no ad networks.</li>
            <li>No analytics or tracking tools, and no crash-reporting services that send data to third parties.</li>
            <li>No location, contacts, photos, microphone or camera access.</li>
            <li>We never sell, rent or trade your data, and we never use your notes to train AI or for marketing.</li>
        </ul>
        <p>The app only asks for an Android permission when a feature needs it — internet access for sync and, in future versions, notifications for reminders or biometrics for fingerprint unlock. Each is used only for that feature.</p>

        <h2 id="sharing">6. Who else sees your data</h2>
        <p>We share data only with the service providers needed to run {{ $appName }}, and only for that purpose:</p>
        <ul>
            <li><strong>Our hosting provider</strong>, which runs the servers and database where synced data is stored.</li>
            <li><strong>Our email provider</strong>, to send password-reset emails (your email address and the email itself).</li>
            <li><strong>Google</strong>, only if you choose "Sign in with Google" — Google confirms your identity to us.</li>
        </ul>
        <p>We may disclose data if the law requires it, for example a valid court order. Even then we cannot hand over the contents of locked notes, because we don't have the key. Sharing notes with other users (a future feature) will only ever happen when you choose to share a specific note.</p>

        <h2 id="retention">7. How long we keep data</h2>
        <ul>
            <li><strong>On your phone:</strong> until you delete it. Notes in the trash are removed for good after the period you choose in Settings (30 days by default).</li>
            <li><strong>On our servers:</strong> while your account exists. When you delete a note forever, its content is wiped from the server and only a small marker is kept, so your other devices know to delete it too.</li>
            <li><strong>When you delete your account:</strong> your account, notes, labels, devices and key data are deleted from our database immediately. Copies in server backups, if any, are overwritten within 30 days.</li>
            <li>Password-reset links expire after 60 minutes.</li>
        </ul>

        <h2 id="rights">8. Your rights and choices</h2>
        <p>You can:</p>
        <ul>
            <li><strong>Access and take your data</strong> — export all notes as text files and JSON from <em>Settings → Backup &amp; restore</em>.</li>
            <li><strong>Correct it</strong> — edit notes and your profile in the app.</li>
            <li><strong>Erase it</strong> — delete notes, sign out and remove notes from a device, or <a href="{{ route('site.delete-account') }}">delete your account</a> (from the app or this website).</li>
            <li><strong>Withdraw consent</strong> — stop syncing at any time by signing out; the app keeps working offline.</li>
            <li><strong>Nominate</strong> someone to exercise these rights for you in case of death or incapacity, by writing to us.</li>
            <li><strong>Complain</strong> — write to our grievance contact at <a href="mailto:{{ $email }}">{{ $email }}</a>. We aim to reply within 7 days and to resolve it within 30 days. If you are not satisfied, you may approach the Data Protection Board of India (or your local data protection authority if you live outside India).</li>
        </ul>

        <h2 id="security">9. Security</h2>
        <p>We use HTTPS for all traffic, store passwords only as bcrypt hashes, give each device its own sign-in token that can be revoked, limit repeated sign-in attempts, and encrypt locked notes and backups on your device. No system is perfectly secure; if we ever learn of a breach affecting your data we will tell you and the authorities as the law requires.</p>

        <h2 id="children">10. Children</h2>
        <p>{{ $appName }} can be used without an account by anyone. Accounts are meant for people aged 18 or over; younger users need the consent of a parent or guardian to create one. We do not knowingly collect children's data without that consent, track children or show them ads. If you believe a child has created an account without consent, contact us and we will delete it.</p>

        <h2 id="website">11. This website</h2>
        <p>This website has no analytics, ads, third-party fonts or trackers. The account-deletion and password-reset forms use one strictly necessary cookie to protect the form against forgery; it holds no tracking ID and expires within two hours. Like most web servers, ours may keep short-lived technical logs (IP address, time, page) to keep the site secure.</p>

        <h2 id="changes">12. Changes and contact</h2>
        <p>If we change this policy we will update the date at the top, and for important changes we will tell you in the app before they take effect. The current version always lives at this address.</p>
        <p>Contact: <a href="mailto:{{ $email }}">{{ $email }}</a>{{ $publisher !== '' ? ' · '.$publisher : '' }} · {{ $site['country'] }}</p>
    </article>
</div>
@endsection
