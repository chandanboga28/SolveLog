# Migration Guide - Adding Miscellaneous Category

## Automatic Migration

The app now includes automatic migration code that will:
- Check if Miscellaneous category exists in your saved default categories
- Add it automatically if missing
- Save the updated list to SharedPreferences

**This happens automatically on next app launch!**

---

## If Miscellaneous Still Doesn't Appear

If after restarting the app you still don't see the Miscellaneous category, you can manually clear the saved data:

### Option 1: Hot Restart (Recommended)
1. Stop the app completely (not just hot reload)
2. Run `flutter run -d macos` again
3. The migration will trigger on launch

### Option 2: Clear App Data (macOS)

#### Method A: Clear Preferences File
```bash
# Find and remove the preferences
rm ~/Library/Containers/com.example.solveLog/Data/Library/Preferences/com.example.solveLog.plist

# Or if not sandboxed:
rm ~/Library/Preferences/com.example.solveLog.plist
```

#### Method B: Use Dart to Clear SharedPreferences
Add this temporary code to clear data:

1. Open `lib/main.dart`
2. Add at the top:
```dart
import 'package:shared_preferences/shared_preferences.dart';
```

3. Modify the `main()` function:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TEMPORARY: Clear default_categories to force re-initialization
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('default_categories');
  
  runApp(const SolveLogApp());
}
```

4. Run the app once
5. Remove the temporary code
6. Run again

### Option 3: Manual Database Tool (Advanced)

If you want to inspect what's saved:

```dart
// Add this as a debug button in platform_selection_screen.dart
FloatingActionButton(
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = prefs.getString('default_categories');
    print('Current defaults: $defaults');
    
    // Force add Miscellaneous
    final categories = [
      {'icon': '💻', 'name': 'Codeforces'},
      {'icon': '⚡', 'name': 'LeetCode'},
      {'icon': '🔷', 'name': 'AtCoder'},
      {'icon': '📝', 'name': 'Miscellaneous'},
    ];
    await prefs.setString('default_categories', json.encode(categories));
    
    // Reload
    _loadCategories();
  },
  child: Icon(Icons.refresh),
)
```

---

## Verify Migration Worked

After restarting the app, you should see:
1. 💻 Codeforces
2. ⚡ LeetCode
3. 🔷 AtCoder
4. 📝 **Miscellaneous** (NEW!)
5. Any custom categories you created
6. ➕ Add Category button

---

## How the Migration Works

### Code in `platform_selection_screen.dart`:

```dart
// Load existing default categories
if (defaultCategoriesJson != null) {
  final List<dynamic> defaults = json.decode(defaultCategoriesJson);
  _defaultCategories = defaults.map(...).toList();
  
  // Migration: Add Miscellaneous if it doesn't exist
  final hasMiscellaneous = _defaultCategories.any(
    (cat) => cat['name'] == 'Miscellaneous'
  );
  if (!hasMiscellaneous) {
    _defaultCategories.add({
      'icon': '📝',
      'name': 'Miscellaneous',
    });
    // Save updated list
    await prefs.setString('default_categories', json.encode(_defaultCategories));
  }
}
```

**What it does:**
1. Loads existing default categories from SharedPreferences
2. Checks if "Miscellaneous" exists in the list
3. If not found, adds it to the list
4. Saves the updated list back to SharedPreferences
5. App now shows all 4 default categories

---

## Testing After Migration

### Test 1: Verify Miscellaneous Appears
- ✅ Open app
- ✅ See 📝 Miscellaneous in category list

### Test 2: Verify Protection Works
- ✅ Long-press on Miscellaneous
- ✅ See warning: "Miscellaneous category cannot be edited or deleted"
- ✅ No edit/delete options appear

### Test 3: Verify Optional Fields
- ✅ Open Miscellaneous category
- ✅ Click "Add Problem"
- ✅ See "Rating (Optional)"
- ✅ See "Problem Link (Optional)"
- ✅ Leave both empty and save successfully

### Test 4: Verify Other Categories Unchanged
- ✅ Open Codeforces
- ✅ Add problem still requires rating and link
- ✅ Existing problems still visible

---

## Troubleshooting

### Issue: Miscellaneous still not appearing

**Solution 1**: Force stop and restart
```bash
# Kill the app process
pkill -f "SolveLog"

# Run again
flutter run -d macos
```

**Solution 2**: Check SharedPreferences location
```bash
# Find where preferences are stored
find ~/Library -name "*solveLog*" -o -name "*solvelog*" 2>/dev/null
```

**Solution 3**: Clear build cache
```bash
cd /Users/bogachandan/SolveLog
flutter clean
flutter pub get
flutter run -d macos
```

### Issue: Migration runs but category disappears

This could mean the category is being added but not displayed. Check:
1. The `_defaultCategories` list in state
2. The build method correctly renders default categories
3. No filter is hiding it

**Debug**: Add print statement:
```dart
print('Default categories loaded: $_defaultCategories');
```

---

## Why Migration is Needed

### Before Update:
```json
{
  "default_categories": [
    {"icon": "💻", "name": "Codeforces"},
    {"icon": "⚡", "name": "LeetCode"},
    {"icon": "🔷", "name": "AtCoder"}
  ]
}
```

### After Migration:
```json
{
  "default_categories": [
    {"icon": "💻", "name": "Codeforces"},
    {"icon": "⚡", "name": "LeetCode"},
    {"icon": "🔷", "name": "AtCoder"},
    {"icon": "📝", "name": "Miscellaneous"}
  ]
}
```

The migration code automatically updates old data to include the new Miscellaneous category without losing your existing categories or custom categories!

---

## Summary

✅ **Migration is automatic** - just restart the app  
✅ **Non-destructive** - keeps all existing categories  
✅ **One-time operation** - runs once and saves result  
✅ **Backward compatible** - works with old and new installations  

Your Miscellaneous category should appear after the next app restart! 🎉
