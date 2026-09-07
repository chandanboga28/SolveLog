# QUICK FIX - Add This to Supabase Dashboard NOW

## Go to Supabase Dashboard:
https://supabase.com/dashboard/project/jhndmiuhbiyftnafhphk

## Add Redirect URL:

1. **Authentication** → **URL Configuration**
2. **Redirect URLs** section
3. Click **Add URL**
4. Add: `io.supabase.solvelog://login-callback`
5. Click **Save**

## That's it - try login again!

The app is now configured to use this redirect URL. Once you add it to Supabase, Google login will work.
