@php
    $appName = config('app.name');
    $site = config('huenote.site');
    $pageTitle = trim($__env->yieldContent('title'));
    $noindex = $__env->hasSection('noindex');
    $nav = [
        'site.home' => 'Home',
        'site.privacy' => 'Privacy',
        'site.support' => 'Support',
    ];
@endphp
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $pageTitle !== '' ? $pageTitle.' · '.$appName : $appName.' — colourful notes that stay yours' }}</title>
    <meta name="description" content="@yield('description', $appName.' is a free, colour-coded notes and checklist app for Android. Works offline, locks private notes with a master password, and has no ads or tracking.')">
    <meta name="theme-color" content="#fff8f1" media="(prefers-color-scheme: light)">
    <meta name="theme-color" content="#17130e" media="(prefers-color-scheme: dark)">
    @if ($noindex)
        <meta name="robots" content="noindex">
    @endif
    <meta property="og:title" content="@yield('title', $appName)">
    <meta property="og:description" content="@yield('description', 'Free, colour-coded notes for Android. Offline-first, no ads, no tracking.')">
    <meta property="og:image" content="{{ asset('images/screens/home-light.webp') }}">
    <link rel="icon" href="{{ asset('favicon.svg') }}" type="image/svg+xml">
    <link rel="stylesheet" href="{{ asset('css/site.css') }}?v={{ @filemtime(public_path('css/site.css')) }}">
</head>
<body>
<a class="skip" href="#main">Skip to content</a>
<header class="site-header @yield('header-class')">
    <div class="wrap">
        <a class="brand" href="{{ route('site.home') }}">@include('site.partials.logo'){{ $appName }}</a>
        <nav class="nav" aria-label="Main">
            @foreach ($nav as $route => $label)
                <a href="{{ route($route) }}" @class(['hide-sm' => $route === 'site.home']) @if (request()->routeIs($route)) aria-current="page" @endif>{{ $label }}</a>
            @endforeach
        </nav>
    </div>
</header>

<main id="main">
    @yield('content')
</main>

<footer class="site-footer">
    <div class="wrap">
        <div>
            <a class="brand" href="{{ route('site.home') }}">@include('site.partials.logo'){{ $appName }}</a>
            <p style="margin:.6em 0 0">Free forever. No ads. No tracking.</p>
            <p style="margin:.2em 0 0">© {{ date('Y') }} {{ $site['publisher'] !== '' ? $site['publisher'] : $appName }} · Made in {{ $site['country'] }}</p>
        </div>
        <nav aria-label="Footer">
            <a href="{{ route('site.privacy') }}">Privacy policy</a>
            <a href="{{ route('site.terms') }}">Terms of use</a>
            <a href="{{ route('site.support') }}">Help &amp; support</a>
            <a href="{{ route('site.delete-account') }}">Delete account</a>
            <a href="mailto:{{ $site['support_email'] }}">Contact</a>
        </nav>
    </div>
</footer>
<script>
    (function () {
        var h = document.querySelector('.site-header');
        if (!h) return;
        var on = function () { h.classList.toggle('scrolled', window.scrollY > 8); };
        on(); window.addEventListener('scroll', on, { passive: true });
    })();
</script>
</body>
</html>
