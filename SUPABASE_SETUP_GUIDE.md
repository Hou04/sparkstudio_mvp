# 🔐 Supabase Automatic Authentication Setup Guide

This guide will help you set up automatic authentication with Supabase for your SparkStudio Flutter app.

## 📋 Prerequisites

1. **Supabase Account**: Create a free account at [supabase.com](https://supabase.com)
2. **Flutter Project**: Your SparkStudio project should be ready
3. **Environment Variables**: Your `.env` file should contain your Supabase credentials

## 🚀 Step-by-Step Setup

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - **Name**: `sparkstudio-mvp`
   - **Database Password**: Choose a strong password
   - **Region**: Choose closest to your users
5. Click "Create new project"
6. Wait for the project to be created (2-3 minutes)

### Step 2: Get Your Supabase Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (looks like: `https://your-project-id.supabase.co`)
   - **anon public** key (starts with `eyJ...`)

3. Update your `.env` file:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...your-anon-key
```

### Step 3: Set Up Database Tables

**Option A: Run All at Once (Recommended)**
1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy and paste the contents of `supabase_setup.sql` (created in your project)
4. Click "Run" to execute the SQL

**Option B: Run Step by Step (If you encounter errors)**
1. In your Supabase dashboard, go to **SQL Editor**
2. Copy and paste the contents of `supabase_setup_simple.sql`
3. Run each step individually by selecting the relevant SQL and clicking "Run"

**Important Notes:**
- The `auth.users` table is managed by Supabase and cannot be modified directly
- The script creates a `profiles` table that extends the auth system
- If you get an error about "must be owner of table users", that's normal - just ignore it

This will create:
- `profiles` table for user profiles (extends auth.users)
- `creative_prompts` table for daily challenges
- `creative_submissions` table for user submissions
- Row Level Security (RLS) policies
- Storage bucket for media files

### Step 4: Configure Authentication Settings

1. Go to **Authentication** → **Settings**
2. **URL Configuration**:
   - Add your app's URL to "Site URL"
   - For development: `http://localhost:3000`
   - For production: your actual domain

3. **Auth Providers**:
   - **Email**: Enable and set "Enable email confirmations" to `false` (for development)
   - **Google**: Leave disabled (we're using email-only authentication)
   - **Apple**: Leave disabled (we're using email-only authentication)

### Step 5: Test Your Setup

1. Run your Flutter app: `flutter run`
2. Try creating a new account
3. Try signing in
4. Check the Supabase dashboard to see if users are created

## 🔧 Troubleshooting

### Common Issues:

1. **"must be owner of table users" error**:
   - This is normal! The `auth.users` table is managed by Supabase
   - The script creates a `profiles` table that extends the auth system
   - You can safely ignore this error and continue

2. **"Invalid API key" error**:
   - Check your `.env` file has the correct credentials
   - Make sure you're using the `anon` key, not the `service_role` key

3. **"User not found" error**:
   - Check if RLS policies are set up correctly
   - Verify the `profiles` table was created

4. **"Permission denied" error**:
   - Check RLS policies in Supabase dashboard
   - Make sure users are authenticated

5. **"provider is not enabled" error**:
   - This error won't occur with email-only authentication
   - If you see this error, make sure you're not trying to use OAuth providers

### Debug Steps:

1. Check Supabase logs in the dashboard
2. Use Flutter debug console to see error messages
3. Verify your `.env` file is loaded correctly
4. Test with a simple sign-up first

## 📱 App Configuration

### Deep Links (Optional for Email Auth):
Deep links are not required for email-only authentication, but you can add them if you plan to use OAuth providers in the future.

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

**iOS** (`ios/Runner/Info.plist`):
No additional configuration needed for email-only authentication.

## 🎉 You're All Set!

Your SparkStudio app now has:
- ✅ Email/password authentication
- ✅ User profiles
- ✅ Creative prompts and submissions
- ✅ Secure data access with RLS
- ✅ Session management
- ✅ Password reset functionality

## 🔄 Next Steps

1. **Test thoroughly**: Try email sign-up and sign-in
2. **Add real data**: Create some creative prompts in Supabase
3. **Customize UI**: Adjust the authentication screens to match your brand
4. **Add features**: Implement additional auth features like profile editing
5. **Deploy**: Set up production environment with proper URLs

## 📚 Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Flutter Supabase Documentation](https://supabase.com/docs/guides/getting-started/flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

---

**Need help?** Check the Supabase community forum or create an issue in your project repository.
