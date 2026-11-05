# HueNote — Laravel API

All endpoints under `/api/v1` — contract in `../docs/05-api-spec.md`.

```bash
composer install
cp .env.example .env && php artisan key:generate   # set DB_* (MySQL)
php artisan migrate
php artisan serve                                   # http://127.0.0.1:8000/api/v1/health
composer lint    # pint --test + larastan
composer test    # Pest (uses MySQL database `huenote_test`, see phpunit.xml)
```
