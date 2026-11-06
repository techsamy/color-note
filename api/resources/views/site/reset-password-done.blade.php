@extends('site.layout')

@section('title', 'Password changed')
@section('noindex', true)
@section('header-class', 'solid')

@section('content')
<div class="wrap" style="padding:72px 20px">
    <div class="form-card success" style="margin:0 auto">
        <div class="badge">@include('site.partials.icon', ['name' => 'check'])</div>
        <h1 style="font-size:1.8rem">Password changed</h1>
        <p>Open {{ config('app.name') }} on your phone and sign in with your new password.</p>
        <p style="color:var(--muted)">For your safety, all devices were signed out. Your notes are safe and will sync again after you sign in.</p>
    </div>
</div>
@endsection
