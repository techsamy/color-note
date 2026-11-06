@extends('site.layout')

@php
    $appName = config('app.name');
    $features = [
        ['palette', 'red', 'Nine colours', 'Give every note a colour and a name — Work, Shopping, Ideas. Filter your whole list by colour in one tap.'],
        ['checklist', 'green', 'Checklists that behave', 'Tick items off and they move to the bottom. Drag to reorder. Turn any note into a checklist and back.'],
        ['lock', 'purple', 'Master password', 'Lock private notes with one password. They are encrypted on your phone (AES-256), and a recovery key keeps you from getting locked out.'],
        ['offline', 'blue', 'Works offline', 'No account needed. Everything is saved on your phone the moment you type — no internet, no waiting.'],
        ['sync', 'yellow', 'Optional sync', 'Sign in only if you want to. Your notes follow you to a new phone, and edits from two devices are never silently lost.'],
        ['backup', 'orange', 'Backup & export', 'Make an encrypted backup file, restore it anywhere, or export your notes as plain text. Your notes are never trapped.'],
    ];
    $shots = [
        ['home-light', 'Your notes, by colour', 'Grid or list, pinned notes on top.'],
        ['editor-light', 'Simple checklists', 'Done items drop to the bottom.'],
        ['home-dark', 'Easy on the eyes', 'A proper dark theme.'],
        ['locked-dark', 'Private notes stay private', 'Locked with your master password.'],
    ];
@endphp

@section('content')
<section class="hero">
    <div class="wrap">
        <div>
            <div class="eyebrow">
                <span class="chip"><i style="background:#43A047"></i>Free forever</span>
                <span class="chip"><i style="background:#1E88E5"></i>No ads</span>
                <span class="chip"><i style="background:#8E24AA"></i>No tracking</span>
            </div>
            <h1>Colourful notes that <span class="hl">stay yours.</span></h1>
            <p class="lead">{{ $appName }} is a fast, simple notes and checklist app for Android. Colour-code everything, lock what's private, and keep working without the internet.</p>
            <div class="cta">
                @include('site.partials.play-button')
                <a class="btn btn-ghost" href="#features">See what it does</a>
            </div>
            <p class="hero-note">Android first · iPhone later</p>
            <div class="swatches" aria-hidden="true">
                @foreach (['#E53935', '#FB8C00', '#FDD835', '#43A047', '#1E88E5', '#8E24AA', '#212121', '#9E9E9E', '#FFFFFF'] as $c)
                    <span style="background:{{ $c }}"></span>
                @endforeach
            </div>
        </div>
        <div class="phones">
            <div class="phone p1"><img src="{{ asset('images/screens/home-light.webp') }}" width="600" height="1299" alt="{{ $appName }} home screen showing colourful notes in a grid: a pinned green Groceries checklist, a blue Trip to Goa note and a yellow Book ideas note."></div>
            <div class="phone p2"><img src="{{ asset('images/screens/home-dark.webp') }}" width="600" height="1299" alt="The same notes in dark theme, shown as a list." loading="lazy"></div>
        </div>
    </div>
</section>

<section id="features">
    <div class="wrap">
        <div class="section-head">
            <h2>Everything a notes app should do. Nothing it shouldn't.</h2>
            <p>No feeds, no clutter, no selling your data. Just notes that open instantly and are there when you need them.</p>
        </div>
        <div class="features">
            @foreach ($features as [$icon, $colour, $title, $text])
                <article class="card bg-{{ $colour }}">
                    <div class="ico">@include('site.partials.icon', ['name' => $icon])</div>
                    <h3>{{ $title }}</h3>
                    <p>{{ $text }}</p>
                </article>
            @endforeach
        </div>
    </div>
</section>

<section class="alt" id="screens">
    <div class="wrap">
        <div class="section-head">
            <h2>Take a look</h2>
            <p>Real screens from the app.</p>
        </div>
        <div class="gallery">
            @foreach ($shots as [$file, $title, $caption])
                <figure>
                    <div class="phone"><img src="{{ asset('images/screens/'.$file.'.webp') }}" width="600" height="1299" alt="{{ $title }} — {{ $caption }}" loading="lazy"></div>
                    <figcaption><b>{{ $title }}</b><span>{{ $caption }}</span></figcaption>
                </figure>
            @endforeach
        </div>
    </div>
</section>

<section id="privacy">
    <div class="wrap">
        <div class="promise">
            <div>
                <h2>Our privacy promise</h2>
                <p>Notes are personal. {{ $appName }} is built so that we know as little about you as possible — and can read even less.</p>
                <p><a href="{{ route('site.privacy') }}">Read the full privacy policy →</a></p>
            </div>
            <ul>
                <li>@include('site.partials.icon', ['name' => 'block'])<div><b>No ads, no trackers, no analytics</b><span>The app contains no advertising or tracking code. Nothing is sold, ever.</span></div></li>
                <li>@include('site.partials.icon', ['name' => 'offline'])<div><b>No account? Nothing leaves your phone.</b><span>Without signing in, the app never talks to our servers.</span></div></li>
                <li>@include('site.partials.icon', ['name' => 'shield'])<div><b>Locked notes are unreadable to us</b><span>They are encrypted on your phone before syncing. We store only scrambled data and never your master password.</span></div></li>
                <li>@include('site.partials.icon', ['name' => 'delete'])<div><b>Leave any time</b><span>Delete your account from the app or <a href="{{ route('site.delete-account') }}">from this website</a>; your synced data is removed right away.</span></div></li>
            </ul>
        </div>
    </div>
</section>

<section class="alt" style="padding:56px 0">
    <div class="wrap">
        <div class="section-head" style="margin-bottom:20px">
            <h2>On the way</h2>
            <p>{{ $appName }} is young and growing. Coming in the next updates:</p>
        </div>
        <div class="soon">
            <span class="chip"><i style="background:#E53935"></i>Reminders</span>
            <span class="chip"><i style="background:#FB8C00"></i>Home-screen widgets</span>
            <span class="chip"><i style="background:#FDD835"></i>Calendar view</span>
            <span class="chip"><i style="background:#43A047"></i>Fingerprint unlock</span>
            <span class="chip"><i style="background:#1E88E5"></i>Share notes with friends</span>
            <span class="chip"><i style="background:#8E24AA"></i>Google sign-in</span>
        </div>
    </div>
</section>
@endsection
