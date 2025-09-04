-- EduBot Admin Dashboard Database Schema
-- This script should be run on your Supabase database to create the required tables and triggers

-- Create profiles table to store user information accessible by admin
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT,
  account_type TEXT NOT NULL DEFAULT 'guest' CHECK (account_type IN ('guest', 'registered', 'premium', 'superadmin')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
  is_email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  premium_expires_at TIMESTAMPTZ,
  total_questions INTEGER NOT NULL DEFAULT 0,
  daily_questions INTEGER NOT NULL DEFAULT 0,
  last_question_at TIMESTAMPTZ,
  suspension_reason TEXT,
  suspended_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create function to sync auth.users with profiles table
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    name,
    account_type,
    is_email_verified
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NULL),
    CASE 
      WHEN NEW.raw_user_meta_data->>'is_superadmin' = 'true' THEN 'superadmin'
      WHEN NEW.raw_user_meta_data->>'is_premium' = 'true' THEN 'premium'
      WHEN NEW.email_confirmed_at IS NOT NULL THEN 'registered'
      ELSE 'guest'
    END,
    NEW.email_confirmed_at IS NOT NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to sync new users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Create function to sync user updates
CREATE OR REPLACE FUNCTION handle_user_update()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET
    email = NEW.email,
    name = COALESCE(NEW.raw_user_meta_data->>'name', name),
    is_email_verified = NEW.email_confirmed_at IS NOT NULL,
    account_type = CASE 
      WHEN NEW.raw_user_meta_data->>'is_superadmin' = 'true' THEN 'superadmin'
      WHEN NEW.raw_user_meta_data->>'is_premium' = 'true' THEN 'premium'
      WHEN NEW.email_confirmed_at IS NOT NULL THEN 'registered'
      ELSE 'guest'
    END,
    updated_at = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to sync user updates
CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_user_update();

-- Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Superadmins can read all profiles
CREATE POLICY "Superadmins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'is_superadmin' = 'true'
    )
  );

-- Superadmins can update all profiles
CREATE POLICY "Superadmins can update all profiles" ON profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'is_superadmin' = 'true'
    )
  );

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile (limited fields)
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_account_type ON profiles(account_type);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at);
CREATE INDEX IF NOT EXISTS idx_profiles_premium_expires_at ON profiles(premium_expires_at);

-- Insert sample data for testing (optional)
-- Uncomment the following lines to insert test data

/*
-- Insert a superadmin user (you'll need to replace the UUID with an actual user ID)
INSERT INTO profiles (
  id, 
  email, 
  name, 
  account_type, 
  is_email_verified
) VALUES (
  '00000000-0000-0000-0000-000000000000', -- Replace with actual superadmin user ID
  'admin@edubot.app',
  'Admin User',
  'superadmin',
  true
) ON CONFLICT (id) DO NOTHING;

-- Insert sample users for testing
INSERT INTO profiles (
  id, 
  email, 
  name, 
  account_type, 
  is_email_verified,
  total_questions,
  daily_questions
) VALUES 
  (gen_random_uuid(), 'user1@example.com', 'John Doe', 'registered', true, 45, 12),
  (gen_random_uuid(), 'user2@example.com', 'Jane Smith', 'premium', true, 150, 25),
  (gen_random_uuid(), 'guest@example.com', 'Guest User', 'guest', false, 5, 5)
ON CONFLICT (id) DO NOTHING;
*/

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON TABLE profiles TO authenticated;
GRANT SELECT ON TABLE profiles TO anon;