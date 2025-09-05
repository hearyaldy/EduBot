-- EduBot Questions and Explanations Database Schema
-- Run this after the main database_schema.sql to add question history storage

-- Create questions table to store the last 10 questions per user
CREATE TABLE IF NOT EXISTS public.questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL CHECK (question_type IN ('text', 'image', 'voice')),
  subject TEXT,
  image_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create explanations table to store AI explanations
CREATE TABLE IF NOT EXISTS public.explanations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID REFERENCES public.questions(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  answer TEXT NOT NULL,
  steps JSONB DEFAULT '[]',
  parent_friendly_tip TEXT,
  real_world_example TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE explanations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for questions table
-- Users can only see their own questions
CREATE POLICY "Users can view own questions" ON questions
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own questions
CREATE POLICY "Users can insert own questions" ON questions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own questions
CREATE POLICY "Users can delete own questions" ON questions
  FOR DELETE USING (auth.uid() = user_id);

-- Superadmins can view all questions (for admin dashboard)
CREATE POLICY "Superadmins can view all questions" ON questions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'is_superadmin' = 'true'
    )
  );

-- RLS Policies for explanations table
-- Users can only see their own explanations
CREATE POLICY "Users can view own explanations" ON explanations
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own explanations
CREATE POLICY "Users can insert own explanations" ON explanations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own explanations
CREATE POLICY "Users can delete own explanations" ON explanations
  FOR DELETE USING (auth.uid() = user_id);

-- Superadmins can view all explanations
CREATE POLICY "Superadmins can view all explanations" ON explanations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'is_superadmin' = 'true'
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_questions_user_id ON questions(user_id);
CREATE INDEX IF NOT EXISTS idx_questions_created_at ON questions(created_at);
CREATE INDEX IF NOT EXISTS idx_questions_user_created ON questions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_explanations_question_id ON explanations(question_id);
CREATE INDEX IF NOT EXISTS idx_explanations_user_id ON explanations(user_id);

-- Create function to maintain only last 10 questions per user
CREATE OR REPLACE FUNCTION maintain_question_limit()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete old questions if user has more than 10
  DELETE FROM questions 
  WHERE user_id = NEW.user_id 
    AND id NOT IN (
      SELECT id FROM questions 
      WHERE user_id = NEW.user_id 
      ORDER BY created_at DESC 
      LIMIT 10
    );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically maintain question limit
CREATE TRIGGER maintain_question_limit_trigger
  AFTER INSERT ON questions
  FOR EACH ROW
  EXECUTE FUNCTION maintain_question_limit();

-- Grant necessary permissions
GRANT ALL ON TABLE questions TO authenticated;
GRANT ALL ON TABLE explanations TO authenticated;
GRANT SELECT ON TABLE questions TO anon;
GRANT SELECT ON TABLE explanations TO anon;