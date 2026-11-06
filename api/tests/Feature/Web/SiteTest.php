<?php

declare(strict_types=1);

use App\Models\Note;
use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;

beforeEach(function (): void {
    config([
        'app.name' => 'HueNote',
        'huenote.site.support_email' => 'help@example.com',
        'huenote.site.publisher' => '',
        'huenote.site.play_store_url' => '',
    ]);
});

describe('public pages', function (): void {
    it('renders every page with the app name and the shared footer', function (string $path, string $heading): void {
        $this->get($path)
            ->assertOk()
            ->assertHeader('Content-Type', 'text/html; charset=utf-8')
            ->assertSee($heading, false)
            ->assertSee('HueNote')
            ->assertSee(route('site.privacy'))
            ->assertSee(route('site.delete-account'))
            ->assertSee('mailto:help@example.com', false)
            ->assertDontSee('Laravel');
    })->with([
        'home' => ['/', 'Colourful notes that'],
        'privacy' => ['/privacy', 'Privacy policy'],
        'terms' => ['/terms', 'Terms of use'],
        'support' => ['/support', 'Help &amp; support'],
        'delete account' => ['/delete-account', 'Delete your HueNote account'],
    ]);

    it('shows the real app screenshots on the home page', function (): void {
        $response = $this->get('/')->assertOk();
        foreach (['home-light', 'editor-light', 'home-dark', 'locked-dark'] as $shot) {
            $response->assertSee("images/screens/{$shot}.webp", false);
            expect(public_path("images/screens/{$shot}.webp"))->toBeFile();
        }
    });

    it('loads nothing from third parties', function (string $path): void {
        $html = (string) $this->get($path)->getContent();
        preg_match_all('/(?:src|href)="(https?:[^"]+)"/', $html, $m);
        $external = array_filter($m[1], fn (string $url): bool => ! str_starts_with($url, (string) config('app.url')));
        expect($external)->toBe([]);
    })->with(['/', '/privacy', '/support']);

    it('says "coming soon" until a Play Store link is configured', function (): void {
        $this->get('/')->assertSee('Coming soon to')->assertDontSee('play.google.com');

        config(['huenote.site.play_store_url' => 'https://play.google.com/store/apps/details?id=com.samy.huenote']);
        $this->get('/')->assertSee('Get it on')->assertSee('play.google.com/store/apps/details?id=com.samy.huenote', false);
    });

    it('names the publisher on the legal pages only when configured', function (): void {
        $this->get('/privacy')->assertDontSee('made by');

        config(['huenote.site.publisher' => 'Jane Example']);
        $this->get('/privacy')->assertSee('made by Jane Example');
        $this->get('/terms')->assertSee('Jane Example');
    });

    it('keeps the API JSON-only while the site renders HTML', function (): void {
        $this->get('/api/v1/nope')->assertNotFound()->assertJsonPath('error.code', 'NOT_FOUND');
    });
});

describe('delete account on the web', function (): void {
    it('deletes the account, its notes and all tokens', function (): void {
        $user = User::factory()->create(['email' => 'a@example.com', 'password' => Hash::make('secret-pass')]);
        $user->createToken((string) Str::uuid());
        $this->withHeader('X-Device-Id', (string) Str::uuid());
        Note::query()->create([
            'id' => (string) Str::uuid7(), 'owner_id' => $user->id, 'version' => 1, 'type' => 0,
            'title' => 't', 'body' => 'b', 'client_created_at' => 1, 'client_updated_at' => 1,
        ]);

        $this->post('/delete-account', ['email' => ' A@example.com ', 'password' => 'secret-pass', 'confirm' => '1'])
            ->assertOk()
            ->assertSee('Your account is deleted');

        expect(User::query()->count())->toBe(0)
            ->and(Note::query()->count())->toBe(0)
            ->and(DB::table('personal_access_tokens')->count())->toBe(0);
    });

    it('gives the same answer for a wrong password, an unknown email and a Google-only account', function (array $input): void {
        User::factory()->create(['email' => 'a@example.com', 'password' => Hash::make('secret-pass')]);
        User::factory()->create(['email' => 'g@example.com', 'password' => null, 'google_id' => 'sub-1']);

        $this->from('/delete-account')
            ->post('/delete-account', [...$input, 'confirm' => '1'])
            ->assertRedirect('/delete-account')
            ->assertSessionHasErrors(['password' => "That email and password don't match an account."]);

        expect(User::query()->count())->toBe(2);
    })->with([
        'wrong password' => [['email' => 'a@example.com', 'password' => 'nope-nope']],
        'unknown email' => [['email' => 'x@example.com', 'password' => 'secret-pass']],
        'google-only' => [['email' => 'g@example.com', 'password' => 'anything']],
    ]);

    it('requires the confirmation tick and valid fields', function (): void {
        User::factory()->create(['email' => 'a@example.com', 'password' => Hash::make('secret-pass')]);

        $this->from('/delete-account')
            ->post('/delete-account', ['email' => 'not-an-email', 'password' => ''])
            ->assertRedirect('/delete-account')
            ->assertSessionHasErrors(['email', 'password', 'confirm']);

        expect(User::query()->count())->toBe(1);
    });

    it('is rate limited', function (): void {
        foreach (range(1, 10) as $_) {
            $this->post('/delete-account', ['email' => 'x@example.com', 'password' => 'p', 'confirm' => '1']);
        }
        $this->post('/delete-account', ['email' => 'x@example.com', 'password' => 'p', 'confirm' => '1'])
            ->assertTooManyRequests();
    });
});

describe('reset password on the web', function (): void {
    it('is the page the reset email links to, prefilled from the link', function (): void {
        Notification::fake();
        $user = User::factory()->create(['email' => 'a@example.com']);
        Password::sendResetLink(['email' => 'a@example.com']);

        Notification::assertSentTo($user, ResetPassword::class, function (ResetPassword $n) use ($user): bool {
            $url = $n->toMail($user)->actionUrl;
            $path = (string) parse_url($url, PHP_URL_PATH);
            parse_str((string) parse_url($url, PHP_URL_QUERY), $query);

            $this->get($path.'?'.http_build_query($query))
                ->assertOk()
                ->assertSee('Choose a new password')
                ->assertSee('value="a@example.com"', false)
                ->assertSee('value="'.$query['token'].'"', false);

            return $path === '/reset-password';
        });
    });

    it('sets the new password and signs out every device', function (): void {
        $user = User::factory()->create(['email' => 'a@example.com', 'password' => Hash::make('old-password')]);
        $user->createToken((string) Str::uuid());
        $token = Password::createToken($user);

        $this->post('/reset-password', [
            'email' => 'a@example.com', 'token' => $token,
            'password' => 'new-password-1', 'password_confirmation' => 'new-password-1',
        ])->assertOk()->assertSee('Password changed');

        expect(Hash::check('new-password-1', (string) $user->fresh()?->password))->toBeTrue()
            ->and($user->tokens()->count())->toBe(0);
    });

    it('rejects an invalid token without changing anything', function (): void {
        $user = User::factory()->create(['email' => 'a@example.com', 'password' => Hash::make('old-password')]);

        $this->from('/reset-password?token=bad&email=a@example.com')
            ->post('/reset-password', [
                'email' => 'a@example.com', 'token' => 'bad',
                'password' => 'new-password-1', 'password_confirmation' => 'new-password-1',
            ])
            ->assertRedirect()
            ->assertSessionHasErrors('token');

        expect(Hash::check('old-password', (string) $user->fresh()?->password))->toBeTrue();
    });

    it('validates the new password', function (): void {
        $this->from('/reset-password')
            ->post('/reset-password', ['email' => 'a@example.com', 'token' => 't', 'password' => 'short', 'password_confirmation' => 'other'])
            ->assertSessionHasErrors('password');
    });

    it('explains an incomplete link', function (): void {
        $this->get('/reset-password')->assertOk()->assertSee('This link is incomplete');
    });
});
