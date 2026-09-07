-- SolveLog Supabase Database Schema
-- Migration: Initial multi-user schema with RLS
-- Created: 2026-09-07
-- 
-- This schema supports multi-user data isolation using Supabase Auth.
-- All user-owned tables have Row Level Security (RLS) enabled.

-- ============================================================================
-- PROFILES TABLE
-- ============================================================================
-- Stores user profile information linked to Supabase auth.users
-- Each authenticated user gets exactly one profile

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    solvelog_id TEXT UNIQUE NOT NULL,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for faster lookups by solvelog_id
CREATE INDEX IF NOT EXISTS idx_profiles_solvelog_id ON public.profiles(solvelog_id);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
-- Users can view any profile (for future social features)
CREATE POLICY "Users can view all profiles"
    ON public.profiles
    FOR SELECT
    USING (true);

-- Users can only insert their own profile
CREATE POLICY "Users can insert own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Users cannot delete profiles (managed by CASCADE)
-- Deletion happens automatically when auth.users row is deleted


-- ============================================================================
-- CATEGORIES TABLE
-- ============================================================================
-- Stores user-created categories (Codeforces, LeetCode, custom, etc.)
-- Each category belongs to exactly one user

CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT,
    type TEXT CHECK (type IN ('predefined', 'custom')) DEFAULT 'custom',
    website TEXT,
    integration_type TEXT CHECK (
        integration_type IN ('none', 'codeforces_api', 'leetcode_api', 'atcoder_api', 'codechef_api')
    ) DEFAULT 'none',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    
    -- Prevent duplicate category names per user
    CONSTRAINT unique_category_per_user UNIQUE (user_id, name)
);

-- Index for faster lookups by user
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON public.categories(user_id);

-- Index for category name searches
CREATE INDEX IF NOT EXISTS idx_categories_user_name ON public.categories(user_id, name);

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- RLS Policies for categories
-- Users can only view their own categories
CREATE POLICY "Users can view own categories"
    ON public.categories
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert categories for themselves
CREATE POLICY "Users can insert own categories"
    ON public.categories
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own categories
CREATE POLICY "Users can update own categories"
    ON public.categories
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own categories
CREATE POLICY "Users can delete own categories"
    ON public.categories
    FOR DELETE
    USING (auth.uid() = user_id);


-- ============================================================================
-- PROBLEMS TABLE
-- ============================================================================
-- Stores coding problems solved by users
-- Each problem belongs to exactly one user and one category

CREATE TABLE IF NOT EXISTS public.problems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    problem_name TEXT NOT NULL,
    problem_id TEXT,
    rating TEXT,
    problem_link TEXT,
    code TEXT,
    question_understanding TEXT,
    problems_faced TEXT,
    any_new_thing_learnt TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for faster lookups by user
CREATE INDEX IF NOT EXISTS idx_problems_user_id ON public.problems(user_id);

-- Index for faster lookups by category
CREATE INDEX IF NOT EXISTS idx_problems_category_id ON public.problems(category_id);

-- Composite index for user+category queries (most common)
CREATE INDEX IF NOT EXISTS idx_problems_user_category ON public.problems(user_id, category_id);

-- Index for created_at ordering (for sorting by date)
CREATE INDEX IF NOT EXISTS idx_problems_created_at ON public.problems(created_at DESC);

-- Enable RLS
ALTER TABLE public.problems ENABLE ROW LEVEL SECURITY;

-- RLS Policies for problems
-- Users can only view their own problems
CREATE POLICY "Users can view own problems"
    ON public.problems
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert problems for themselves
CREATE POLICY "Users can insert own problems"
    ON public.problems
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own problems
CREATE POLICY "Users can update own problems"
    ON public.problems
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own problems
CREATE POLICY "Users can delete own problems"
    ON public.problems
    FOR DELETE
    USING (auth.uid() = user_id);


-- ============================================================================
-- APPROACHES TABLE
-- ============================================================================
-- Stores different approaches/solutions to a problem
-- Each approach belongs to exactly one problem
-- Access is controlled through the parent problem's ownership

CREATE TABLE IF NOT EXISTS public.approaches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    problem_id UUID NOT NULL REFERENCES public.problems(id) ON DELETE CASCADE,
    approach_text TEXT,
    approach_code TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for faster lookups by problem
CREATE INDEX IF NOT EXISTS idx_approaches_problem_id ON public.approaches(problem_id);

-- Enable RLS
ALTER TABLE public.approaches ENABLE ROW LEVEL SECURITY;

-- RLS Policies for approaches
-- Users can view approaches if they own the parent problem
CREATE POLICY "Users can view approaches of own problems"
    ON public.approaches
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.problems
            WHERE problems.id = approaches.problem_id
            AND problems.user_id = auth.uid()
        )
    );

-- Users can insert approaches only for their own problems
CREATE POLICY "Users can insert approaches to own problems"
    ON public.approaches
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.problems
            WHERE problems.id = approaches.problem_id
            AND problems.user_id = auth.uid()
        )
    );

-- Users can update approaches only on their own problems
CREATE POLICY "Users can update approaches of own problems"
    ON public.approaches
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.problems
            WHERE problems.id = approaches.problem_id
            AND problems.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.problems
            WHERE problems.id = approaches.problem_id
            AND problems.user_id = auth.uid()
        )
    );

-- Users can delete approaches only from their own problems
CREATE POLICY "Users can delete approaches of own problems"
    ON public.approaches
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.problems
            WHERE problems.id = approaches.problem_id
            AND problems.user_id = auth.uid()
        )
    );


-- ============================================================================
-- DO_LATER TABLE
-- ============================================================================
-- Stores problems marked as "Do Later" by users
-- Each entry belongs to exactly one user and one category

CREATE TABLE IF NOT EXISTS public.do_later (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    problem_id TEXT,
    problem_link TEXT,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for faster lookups by user
CREATE INDEX IF NOT EXISTS idx_do_later_user_id ON public.do_later(user_id);

-- Index for faster lookups by category
CREATE INDEX IF NOT EXISTS idx_do_later_category_id ON public.do_later(category_id);

-- Composite index for user+category queries
CREATE INDEX IF NOT EXISTS idx_do_later_user_category ON public.do_later(user_id, category_id);

-- Enable RLS
ALTER TABLE public.do_later ENABLE ROW LEVEL SECURITY;

-- RLS Policies for do_later
-- Users can only view their own do_later items
CREATE POLICY "Users can view own do_later items"
    ON public.do_later
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert do_later items for themselves
CREATE POLICY "Users can insert own do_later items"
    ON public.do_later
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own do_later items
CREATE POLICY "Users can update own do_later items"
    ON public.do_later
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own do_later items
CREATE POLICY "Users can delete own do_later items"
    ON public.do_later
    FOR DELETE
    USING (auth.uid() = user_id);


-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER set_updated_at_profiles
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at_categories
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at_problems
    BEFORE UPDATE ON public.problems
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at_approaches
    BEFORE UPDATE ON public.approaches
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();


-- Function to generate unique solvelog_id
CREATE OR REPLACE FUNCTION public.generate_solvelog_id()
RETURNS TEXT AS $$
DECLARE
    new_id TEXT;
    done BOOL := FALSE;
BEGIN
    WHILE NOT done LOOP
        -- Generate random 8-character alphanumeric ID
        new_id := lower(substr(md5(random()::text), 1, 8));
        
        -- Check if it already exists
        IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE solvelog_id = new_id) THEN
            done := TRUE;
        END IF;
    END LOOP;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;


-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, solvelog_id)
    VALUES (
        NEW.id,
        public.generate_solvelog_id()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile when user signs up
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();


-- ============================================================================
-- COMMENTS
-- ============================================================================
-- Add helpful comments to tables and columns

COMMENT ON TABLE public.profiles IS 'User profiles linked to Supabase auth.users. Each user has exactly one profile.';
COMMENT ON COLUMN public.profiles.solvelog_id IS 'Unique SolveLog identifier (8 characters, auto-generated)';
COMMENT ON COLUMN public.profiles.username IS 'Optional username (not enforced unique)';
COMMENT ON COLUMN public.profiles.display_name IS 'Display name for UI';

COMMENT ON TABLE public.categories IS 'User-created categories (Codeforces, LeetCode, custom platforms, etc.)';
COMMENT ON COLUMN public.categories.integration_type IS 'Future API integration type (none, codeforces_api, leetcode_api, etc.)';

COMMENT ON TABLE public.problems IS 'Coding problems solved by users, linked to categories';
COMMENT ON COLUMN public.problems.problem_id IS 'External problem ID (e.g., "1234A" for Codeforces)';
COMMENT ON COLUMN public.problems.code IS 'User solution code';
COMMENT ON COLUMN public.problems.question_understanding IS 'User notes on problem understanding';
COMMENT ON COLUMN public.problems.problems_faced IS 'Challenges encountered while solving';
COMMENT ON COLUMN public.problems.any_new_thing_learnt IS 'New concepts/techniques learned';

COMMENT ON TABLE public.approaches IS 'Different approaches/solutions to a problem. Access controlled via parent problem ownership.';

COMMENT ON TABLE public.do_later IS 'Problems marked as "Do Later" by users';


-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
-- Grant appropriate permissions to authenticated users

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.categories TO authenticated;
GRANT ALL ON public.problems TO authenticated;
GRANT ALL ON public.approaches TO authenticated;
GRANT ALL ON public.do_later TO authenticated;
