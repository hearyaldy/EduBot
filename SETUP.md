# Environment Setup Guide for EduBot

This guide will help you set up the environment variables and API keys needed for EduBot to function properly.

## 🔑 Required Setup

### 1. Create your .env file

Copy the example environment file and customize it:

```bash
cp .env.example .env
```

### 2. Get your OpenAI API Key

1. Go to [OpenAI's website](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to the [API Keys section](https://platform.openai.com/api-keys)
4. Click "Create new secret key"
5. Copy the generated key (it starts with `sk-`)

### 3. Configure your .env file

Open the `.env` file and update the following values:

```env
# Replace with your actual OpenAI API key
OPENAI_API_KEY=sk-your-actual-openai-api-key-here

# Optional: Customize other settings
OPENAI_MODEL=gpt-3.5-turbo
DAILY_FREE_QUESTION_LIMIT=10
APP_ENV=development
```

### 4. Verify your setup

Run the app and check the debug console for configuration status:

```bash
flutter run
```

Look for these messages in the console:
- ✅ No configuration issues = Setup complete!
- ❌ Configuration issues listed = Fix the issues mentioned

## 🔒 Security Best Practices

### ✅ DO:
- Keep your `.env` file local (never commit it)
- Use different API keys for development/production
- Regularly rotate your API keys
- Monitor your OpenAI usage and billing

### ❌ DON'T:
- Commit `.env` files to version control
- Share API keys in chat or email
- Use production API keys in development
- Hardcode secrets in your source code

## 🎛 Available Configuration Options

### OpenAI Settings
```env
OPENAI_API_KEY=sk-your-key-here
OPENAI_MODEL=gpt-3.5-turbo          # or gpt-4 for better quality
OPENAI_MAX_TOKENS=1500              # Maximum response length
OPENAI_TEMPERATURE=0.7              # Creativity level (0.0-2.0)
```

### App Behavior
```env
APP_ENV=development                 # development, staging, production
DEBUG_MODE=true                     # Enable debug features
ENABLE_LOGGING=true                 # Enable detailed logging
```

### Feature Toggles
```env
ENABLE_PREMIUM_FEATURES=true        # Enable premium features
ENABLE_VOICE_INPUT=true             # Enable voice questions
ENABLE_AUDIO_OUTPUT=true            # Enable audio explanations
ENABLE_CAMERA_SCANNING=true         # Enable camera scanning
```

### Usage Limits
```env
DAILY_FREE_QUESTION_LIMIT=10        # Free questions per day
MAX_SAVED_QUESTIONS=100             # Maximum saved questions
MAX_QUESTION_LENGTH=500             # Maximum question length
```

## 🚀 Quick Start Commands

```bash
# 1. Clone and setup
git clone <your-repo>
cd edubot

# 2. Install dependencies
flutter pub get

# 3. Copy environment template
cp .env.example .env

# 4. Edit .env with your API key
# (Use your preferred editor)
nano .env

# 5. Clean and rebuild (first time setup)
flutter clean
flutter pub get

# 5. Run the app
flutter run
```

## 🔧 Troubleshooting

### "OpenAI API key is not configured"
- Check that your `.env` file exists in the project root
- Verify the API key format starts with `sk-`
- Ensure no extra spaces around the key

### "Failed to load .env file"
- Make sure `.env` is in the project root directory
- Check file permissions (should be readable)
- Verify the file is not corrupted

### Android SDK/NDK Version Issues
If you see errors about Android SDK or NDK versions:

```bash
# The project is already configured with:
# - Android SDK 36 (required for camera plugin)
# - Android NDK 27.0.12077973 (required for multiple plugins)

# If you still see issues, try:
flutter clean
flutter pub get
flutter build apk --debug
```

**Note**: The Android configuration in `android/app/build.gradle.kts` has been updated to use:
- `compileSdk = 36`
- `targetSdk = 36` 
- `ndkVersion = "27.0.12077973"`

### "API calls failing"
- Check your OpenAI account has credits
- Verify your API key is active
- Check network connectivity
- Review OpenAI's rate limits

### Debug Mode Information
When `DEBUG_MODE=true`, the app will show:
- Configuration validation results
- API call status
- Feature flag states
- Usage statistics

## 💰 Cost Management

### OpenAI Pricing (as of 2024)
- GPT-3.5 Turbo: ~$0.002 per 1K tokens
- GPT-4: ~$0.03 per 1K tokens

### Estimation for EduBot:
- Average explanation: ~500 tokens
- Cost per explanation: ~$0.001 (GPT-3.5)
- 100 explanations: ~$0.10

### Cost Control Tips:
1. Set usage limits in your OpenAI account
2. Monitor usage in the OpenAI dashboard
3. Use GPT-3.5 for development
4. Implement request caching for repeated questions

## 🆘 Support

If you encounter issues:

1. **Check the console** for configuration warnings
2. **Verify your setup** using the troubleshooting guide
3. **Review the code** in `lib/utils/environment_config.dart`
4. **Create an issue** with your configuration status output

---

**Remember**: Never commit your `.env` file or share your API keys publicly!
