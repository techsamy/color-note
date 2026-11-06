@extends('site.layout')

@php
    $appName = config('app.name');
    $email = config('huenote.site.support_email');
    $faqs = [
        ['Do I need an account?', 'No. '.$appName.' works completely without an account and nothing leaves your phone. Create one only if you want to sync notes between devices or restore them on a new phone.'],
        ['How do I move my notes to a new phone?', 'Either sign in with the same account on the new phone (your notes download automatically), or create a backup file in <em>Settings → Backup &amp; restore</em>, copy it to the new phone and restore it there with the backup password.'],
        ['I forgot my master password', 'Open <em>Settings → Forgot master password</em> and enter the recovery key you saved when you set up the master password. You can then choose a new master password. Without the master password <strong>and</strong> the recovery key, locked notes cannot be opened — not even by us, because we never have the key.'],
        ['I forgot my account password', 'On the sign-in screen tap <em>Forgot password?</em> and enter your email. We will email you a link to choose a new password. The link works for 60 minutes. For safety, every device is signed out afterwards — just sign in again.'],
        ['I see a note called "(conflicted copy)"', 'You edited the same note on two devices before they synced. Instead of throwing one version away, '.$appName.' keeps both. Compare them, keep the one you want and delete the other.'],
        ['Is my data safe?', 'Without an account, it never leaves your phone. With an account, it is sent over HTTPS and stored on our servers. Notes you lock are encrypted on your phone first, so we can\'t read them. Read the <a href="'.route('site.privacy').'">privacy policy</a> for details.'],
        ['How do I export my notes?', 'Go to <em>Settings → Backup &amp; restore → Export as text</em>. You get a zip with one readable .txt file per note plus a notes.json file. Locked notes are left out on purpose.'],
        ['Where is the trash?', 'Open the menu (☰) and choose <em>Trash</em>. Notes stay there for 30 days by default (change it in Settings) and can be restored.'],
        ['How do I delete my account?', 'In the app: <em>Settings → Account &amp; sync → Delete account</em>. Without the app: use the <a href="'.route('site.delete-account').'">delete-account page</a>. Notes on your phone are kept as offline notes.'],
        ['Is it really free? How do you make money?', 'It\'s really free — no ads, no subscriptions, no selling data. '.$appName.' is an independent project.'],
    ];
@endphp

@section('title', 'Help & support')
@section('description', 'Answers to common questions about '.$appName.', and how to contact us.')
@section('header-class', 'solid')

@section('content')
<div class="wrap">
    <header class="page-head">
        <h1>Help &amp; support</h1>
        <p>Answers to the most common questions. Can't find yours? Just email us.</p>
    </header>

    <div class="prose">
        @foreach ($faqs as [$q, $a])
            <details>
                <summary>{{ $q }}</summary>
                <div>{!! $a !!}</div>
            </details>
        @endforeach

        <div class="callout bg-yellow" style="color:var(--n-ink);margin-top:32px">
            <h2 style="margin-top:0;font-size:1.3rem">Still stuck?</h2>
            <p>Write to <a href="mailto:{{ $email }}?subject={{ rawurlencode($appName.' support') }}" style="color:inherit;font-weight:700">{{ $email }}</a>. Tell us your phone model and the app version (<em>Settings → About</em>). Please never send us your passwords or recovery key — we will never ask for them.</p>
        </div>
    </div>
</div>
@endsection
