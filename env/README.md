# env/

Local `--dart-define-from-file` inputs. Only `*.example` files are committed;
every other file in this directory is ignored by git.

```bash
cp env/supabase.dev.json.example env/supabase.dev.json
flutter run --dart-define-from-file=env/supabase.dev.json
```

The two values in here — project URL and **publishable** key — are public by
design and safe in a client. Never put a `service_role`/secret key, a database
password or a management access token in any file under `env/`; the app has no
use for them and the `.gitignore` will not save you from a `git add -f`.
