-- SolveLog Supabase Database Schema
-- Migration: Backfill profiles for existing auth.users
-- Created: 2026-09-07
-- 
-- This migration safely creates profile records for any auth.users
-- that existed before the handle_new_user trigger was deployed.
-- 
-- SAFETY:
-- - Only inserts profiles for users WITHOUT existing profiles
-- - Uses existing generate_solvelog_id() function for unique IDs
-- - Extracts metadata from auth.users.raw_user_meta_data (Google OAuth)
-- - Does NOT modify or delete any existing data
-- - Idempotent: Safe to run multiple times

-- ============================================================================
-- BACKFILL PROFILES FOR EXISTING USERS
-- ============================================================================

DO $$
DECLARE
    user_record RECORD;
    new_solvelog_id TEXT;
    user_display_name TEXT;
    user_username TEXT;
    user_avatar TEXT;
BEGIN
    -- Loop through all auth.users that don't have a profile yet
    FOR user_record IN 
        SELECT 
            u.id,
            u.email,
            u.raw_user_meta_data
        FROM auth.users u
        LEFT JOIN public.profiles p ON u.id = p.id
        WHERE p.id IS NULL  -- Only users without profiles
    LOOP
        -- Generate unique solvelog_id
        new_solvelog_id := public.generate_solvelog_id();
        
        -- Extract display name from Google OAuth metadata
        -- Try multiple possible fields: full_name, name, email
        user_display_name := COALESCE(
            user_record.raw_user_meta_data->>'full_name',
            user_record.raw_user_meta_data->>'name',
            split_part(user_record.email, '@', 1)  -- Fallback to email username
        );
        
        -- Extract username (use email username part)
        user_username := split_part(user_record.email, '@', 1);
        
        -- Extract avatar URL from Google OAuth metadata
        user_avatar := COALESCE(
            user_record.raw_user_meta_data->>'avatar_url',
            user_record.raw_user_meta_data->>'picture'
        );
        
        -- Insert profile
        INSERT INTO public.profiles (
            id,
            solvelog_id,
            username,
            display_name,
            avatar_url,
            created_at,
            updated_at
        ) VALUES (
            user_record.id,
            new_solvelog_id,
            user_username,
            user_display_name,
            user_avatar,
            now(),
            now()
        );
        
        -- Log the backfill (optional, helps verify what was done)
        RAISE NOTICE 'Created profile for user: % (%, SolveLog ID: %)', 
            user_record.email,
            user_record.id,
            new_solvelog_id;
    END LOOP;
    
    -- Summary
    RAISE NOTICE 'Backfill complete. Check output above for details.';
END $$;


-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these after the migration to verify success:

-- Check total auth.users vs profiles (should match)
-- SELECT 
--     (SELECT COUNT(*) FROM auth.users) as total_auth_users,
--     (SELECT COUNT(*) FROM public.profiles) as total_profiles,
--     (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM public.profiles) as missing_profiles;

-- List all profiles with their auth data
-- SELECT 
--     p.id,
--     p.solvelog_id,
--     p.username,
--     p.display_name,
--     u.email,
--     p.created_at
-- FROM public.profiles p
-- JOIN auth.users u ON p.id = u.id
-- ORDER BY p.created_at;
