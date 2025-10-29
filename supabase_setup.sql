-- Supabase Database Setup for SparkStudio
-- Run this in your Supabase SQL Editor

-- Create profiles table (extends auth.users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Create creative_prompts table
CREATE TABLE public.creative_prompts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('photo', 'text', 'video')),
  description TEXT NOT NULL,
  ai_style TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on creative_prompts
ALTER TABLE public.creative_prompts ENABLE ROW LEVEL SECURITY;

-- Create policies for creative_prompts
CREATE POLICY "Anyone can view active prompts" ON public.creative_prompts
  FOR SELECT USING (is_active = true);

-- Create creative_submissions table
CREATE TABLE public.creative_submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  prompt_id UUID REFERENCES public.creative_prompts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content_url TEXT,
  text_content TEXT,
  ai_style TEXT,
  ai_generated_content TEXT,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on creative_submissions
ALTER TABLE public.creative_submissions ENABLE ROW LEVEL SECURITY;

-- Create policies for creative_submissions
CREATE POLICY "Anyone can view public submissions" ON public.creative_submissions
  FOR SELECT USING (is_public = true);

CREATE POLICY "Users can insert own submissions" ON public.creative_submissions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own submissions" ON public.creative_submissions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own submissions" ON public.creative_submissions
  FOR DELETE USING (auth.uid() = user_id);

-- Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Insert sample creative prompts
INSERT INTO public.creative_prompts (title, type, description, ai_style) VALUES
('🌟 Magic Selfie', 'photo', 'Transform your selfie into a fantasy hero! Use AI to add magical elements, mystical backgrounds, or superhero vibes.', 'fantasy'),
('📝 Space Cat Story', 'text', 'Write a short story about a cat who dreams of exploring space. Let AI help you expand your ideas into an epic tale!', 'story'),
('🎬 Daily Vibe Check', 'video', 'Create a 30-second video showing your current mood using creative transitions and effects.', 'cinematic'),
('🎨 Haiku Master', 'text', 'Write a haiku about your favorite season. AI will help you refine the rhythm and imagery.', 'haiku');

-- Create storage bucket for creative media
INSERT INTO storage.buckets (id, name, public) VALUES ('creative_media', 'creative_media', true);

-- Create storage policies
CREATE POLICY "Anyone can view creative media" ON storage.objects
  FOR SELECT USING (bucket_id = 'creative_media');

CREATE POLICY "Authenticated users can upload creative media" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'creative_media' AND auth.role() = 'authenticated');

CREATE POLICY "Users can update own creative media" ON storage.objects
  FOR UPDATE USING (bucket_id = 'creative_media' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own creative media" ON storage.objects
  FOR DELETE USING (bucket_id = 'creative_media' AND auth.uid()::text = (storage.foldername(name))[1]);
