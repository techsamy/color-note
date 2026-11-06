@extends('site.layout')

@section('title', 'Account deleted')
@section('noindex', true)
@section('header-class', 'solid')

@section('content')
<div class="wrap" style="padding:72px 20px">
    <div class="form-card success" style="margin:0 auto">
        <div class="badge">@include('site.partials.icon', ['name' => 'check'])</div>
        <h1 style="font-size:1.8rem">Your account is deleted</h1>
        <p>Your account and all notes stored on our servers have been removed, and every device has been signed out.</p>
        <p style="color:var(--muted)">Notes already on your phone are still there as offline notes. Thank you for trying {{ config('app.name') }}.</p>
        <a class="btn btn-ghost" href="{{ route('site.home') }}">Back to home</a>
    </div>
</div>
@endsection
