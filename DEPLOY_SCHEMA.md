# Deploy Supabase Schema - Quick Guide

## ✅ Ready to Deploy

The Supabase database schema is ready. Here's how to apply it:

---

## Option 1: Supabase Dashboard SQL Editor (Easiest)

1. **Go to your Supabase project:**
   https://supabase.com/dashboard/project/jhndmiuhbiyftnafhphk

2. **Open SQL Editor:**
   Click "SQL Editor" in the left sidebar

3. **Create New Query:**
   Click "New query"

4. **Copy the migration file:**
   ```bash
   cat /Users/bogachandan/SolveLog/supabase/migrations/20260907000000_initial_schema.sql
   ```

5. **Paste into SQL Editor**

6. **Run the query:**
   Click "Run" or press Cmd+Enter

7. **Verify:**
   - Check "Table Editor" - you should see 5 new tables
   - Check "Database" → "Roles" - RLS should be enabled
   - Check "Database" → "Triggers" - you should see triggers

---

## Option 2: Copy-Paste from File

1. Open the migration file in your editor:
   ```
   /Users/bogachandan/SolveLog/supabase/migrations/20260907000000_initial_schema.sql
   ```

2. Copy the entire contents (Cmd+A, Cmd+C)

3. Go to Supabase Dashboard → SQL Editor

4. Paste and Run

---

## What Gets Created:

### **Tables (5):**
- ✅ profiles
- ✅ categories  
- ✅ problems
- ✅ approaches
- ✅ do_later

### **RLS Policies (23):**
- ✅ All tables have Row Level Security enabled
- ✅ Users can only access their own data
- ✅ Approaches protected via parent problem ownership

### **Indexes (11):**
- ✅ Optimized for common queries
- ✅ Fast lookups by user_id, category_id, problem_id

### **Triggers (5):**
- ✅ Auto-create profile on user signup
- ✅ Auto-update timestamps

### **Functions (3):**
- ✅ handle_new_user()
- ✅ handle_updated_at()
- ✅ generate_solvelog_id()

---

## After Deployment:

### Test with SQL Editor:

```sql
-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check your profile was auto-created (after you login)
SELECT * FROM profiles WHERE id = auth.uid();
```

---

## Verify RLS:

1. **Login to your app** (Google OAuth)
2. **Run in SQL Editor:**
   ```sql
   -- Should see your profile
   SELECT * FROM profiles WHERE id = auth.uid();
   
   -- Should be empty (no categories yet)
   SELECT * FROM categories WHERE user_id = auth.uid();
   ```

3. **Try to access another user's data:**
   ```sql
   -- This should return nothing (RLS blocks it)
   SELECT * FROM profiles WHERE id != auth.uid();
   ```

---

## Troubleshooting:

### Error: "relation already exists"
- Tables already created, skip or drop them first
- Or modify migration to use `CREATE TABLE IF NOT EXISTS`

### Error: "permission denied"
- Make sure you're connected as the project owner
- Check that authenticated role has permissions

### RLS Not Working:
- Verify `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` ran
- Check policies exist: `SELECT * FROM pg_policies WHERE schemaname = 'public';`

---

## Next Steps After Deployment:

1. ✅ Schema deployed
2. ⏳ Test authentication (login via Google)
3. ⏳ Verify profile auto-creation
4. ⏳ Test RLS policies
5. ⏳ Implement sync logic (future phase)

---

**Estimated Time:** 2-3 minutes  
**Difficulty:** Easy (just copy-paste and run)  
**Reversibility:** Can drop all tables if needed
