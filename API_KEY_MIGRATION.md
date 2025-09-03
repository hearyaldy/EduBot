# AI Token Migration Guide

## Changes Made

The app has been updated to use user-specific AI tokens instead of a global token to save costs. Here are the key changes:

### 1. Modified AI Service (`lib/services/ai_service.dart`)
- Removed dependency on global API key from .env file
- Added support for user-specific API keys stored in local storage
- Added methods to save/remove user API keys
- Updated validation to check for user-specific keys

### 2. Updated Settings Screen (`lib/screens/settings_screen.dart`)
- Added "AI Configuration" section with API key management
- Provides UI for users to:
  - Add their Google Gemini API key
  - Test API key connection
  - Remove stored API key
  - View instructions on how to obtain an API key

### 3. Environment Configuration (`lib/utils/environment_config.dart`)
- Removed global API key validation
- Updated configuration to reflect user-specific approach

### 4. Environment File (`.env`)
- Removed the global `GEMINI_API_KEY`
- Added comments explaining the new user-specific approach

## How Users Add Their API Key

1. Open the app and go to **Settings**
2. Find the **AI Configuration** section
3. Tap on "API Key Required" 
4. Follow the instructions to get a Google Gemini API key:
   - Visit console.cloud.google.com
   - Create/select a project
   - Enable the Gemini API
   - Create credentials > API key
   - Copy the API key
5. Paste the API key in the dialog and save
6. Test the connection to verify it works

## Instructions for Users to Get API Key

The app now includes built-in instructions that guide users through:
1. Visiting Google Cloud Console
2. Setting up a project
3. Enabling the Gemini API
4. Creating an API key
5. Adding usage limits (optional but recommended)

## Security Notes

- API keys are stored locally on the user's device using secure storage
- Keys are never transmitted to any external service except Google's Gemini API
- Users can remove their API key at any time
- Each user manages their own API costs and usage limits

## Benefits

- **Cost Savings**: No more global API costs - users pay for their own usage
- **Scalability**: App can support unlimited users without increasing API costs
- **Security**: Users control their own API keys and usage
- **Transparency**: Users can monitor their own API usage and costs