# kabachok_lasalsa_front

Flutter project for Frontend of LaSalsa - Task Manager

## Configuration

The backend URL is configurable via a compile-time environment variable. Use
`--dart-define` when running or building the app:

```
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

If no value is provided, `http://localhost:8000` is used by default.
