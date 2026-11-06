@php $playUrl = config('huenote.site.play_store_url'); @endphp
@if ($playUrl !== '' && $playUrl !== null)
    <a class="btn btn-primary" href="{{ $playUrl }}" rel="noopener">
        @include('site.partials.icon', ['name' => 'play'])
        <span><span class="small">Get it on</span><span class="big">Google Play</span></span>
    </a>
@else
    <span class="btn btn-primary" aria-disabled="true">
        @include('site.partials.icon', ['name' => 'play'])
        <span><span class="small">Coming soon to</span><span class="big">Google Play</span></span>
    </span>
@endif
