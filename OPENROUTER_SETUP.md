# OpenRouter AI Integration Setup

## Overview

EduBot now supports **OpenRouter** as an AI provider, giving you access to multiple free AI models including **Google Gemini 2.0 Flash Experimental** - a powerful and fast model perfect for homework explanations.

## Why OpenRouter?

- **Free Models Available**: Access to Gemini 2.0 Flash and other models at no cost
- **No Daily Limits**: Unlike direct API usage, OpenRouter provides generous free tier
- **Multiple Models**: Easy to switch between different AI models
- **Simple Setup**: Just one API key needed

## Current Configuration

The app is configured to use:
- **Model**: `google/gemini-2.0-flash-exp:free`
- **Provider**: OpenRouter
- **Endpoint**: `https://openrouter.ai/api/v1/chat/completions`

## Setup Steps

### 1. Get Your OpenRouter API Key

1. Visit: https://openrouter.ai/keys
2. Sign up or log in with your account
3. Click **"Create Key"**
4. Give it a name (e.g., "EduBot")
5. Copy your API key (starts with `sk-or-v1-...`)

### 2. Add API Key to Your App

Open the `.env` file in your project root and add your API key:

```env
# OpenRouter API Configuration
OPENROUTER_API_KEY=sk-or-v1-your-actual-api-key-here
```

Replace `your-openrouter-api-key-here` with your actual API key from step 1.

### 3. Rebuild the App

```bash
flutter clean
flutter build apk --debug
flutter install
```

## How It Works

When a user asks a question:

1. **Question is sent** to OpenRouter with the Gemini 2.0 Flash model
2. **AI processes** the question with context about grade level and language
3. **Response is parsed** into structured explanation with:
   - Direct answer
   - Step-by-step breakdown
   - Parent-friendly tips
   - Real-world examples
   - Subject classification
   - Difficulty level

## Response Format

The AI returns structured JSON with:

```json
{
  "answer": "Direct answer to the problem",
  "steps": [
    {
      "stepNumber": 1,
      "title": "Step title",
      "description": "Detailed explanation",
      "tip": "Optional parent tip",
      "isKeyStep": true/false
    }
  ],
  "parentFriendlyTip": "Encouraging tip for parents",
  "realWorldExample": "How this applies in real life",
  "subject": "Math/Science/English/etc",
  "difficulty": "elementary/medium/advanced"
}
```

## Language Support

The service supports multiple languages:
- **English** (default)
- **Malay** (Bahasa Malaysia)
- **Spanish** (Español)
- **French** (Français)
- **Chinese** (Simplified Chinese)

The language preference is automatically passed from the app settings.

## Features

### ✅ Parent-Friendly Approach
- Explains concepts in simple language
- Never condescending or judgmental
- Uses real-world examples and analogies
- Breaks down problems into manageable steps

### ✅ Educational Focus
- Step-by-step explanations
- Key concepts highlighted
- Tips for teaching children
- Real-world application examples

### ✅ Customizable
- Grade level adaptation (Elementary, Middle School, High School)
- Multi-language support
- Adjustable temperature and token limits
- Image support (for problem scanning)

## Code Structure

### Service Location
`lib/services/openrouter_ai_service.dart`

### Key Methods

#### `getExplanation()`
Main method to get AI explanation for a question.

```dart
Future<Explanation> getExplanation({
  required String question,
  String? imageBase64,
  String language = 'English',
  String gradeLevel = 'Elementary',
}) async
```

**Parameters:**
- `question`: The homework question text
- `imageBase64`: Optional base64-encoded image of the problem
- `language`: Preferred response language
- `gradeLevel`: Student's grade level for appropriate explanation

**Returns:** `Explanation` object with structured response

### Configuration Check

```dart
if (OpenRouterAIService.isConfigured) {
  // API key is configured, ready to use
} else {
  // Need to configure API key
}
```

## Testing

To test the integration:

1. **Add API Key** to `.env` file
2. **Rebuild** the app
3. **Ask a Question** in the app:
   - Tap "Ask Question" on home screen
   - Enter: "What is 5 + 3?"
   - Select language and grade level
   - Submit

4. **Check Logs** for debug output:
   ```bash
   adb logcat | grep OpenRouterAI
   ```

Expected log output:
```
[OpenRouterAI] === OpenRouter AI Request ===
[OpenRouterAI] Model: google/gemini-2.0-flash-exp:free
[OpenRouterAI] Question: What is 5 + 3?
[OpenRouterAI] Language: English
[OpenRouterAI] Grade: Elementary
[OpenRouterAI] Response status: 200
[OpenRouterAI] ✓ Received response from OpenRouter
```

## Troubleshooting

### Issue: "OpenRouter not configured"

**Solution:**
1. Check `.env` file has `OPENROUTER_API_KEY` set
2. Verify API key is not `your-openrouter-api-key-here`
3. Rebuild app: `flutter clean && flutter build apk --debug`

### Issue: "API error: 401 Unauthorized"

**Solution:**
1. Verify API key is correct
2. Check API key is active on https://openrouter.ai/keys
3. Make sure key has not expired

### Issue: "API error: 429 Too Many Requests"

**Solution:**
1. Wait a few minutes before retrying
2. Check your usage on OpenRouter dashboard
3. Consider upgrading to paid tier if needed

### Issue: Response parsing errors

**Solution:**
1. Check logs for detailed error: `adb logcat | grep OpenRouterAI`
2. Verify the model is returning JSON format
3. Check if the JSON structure matches expected format

## Free Model Limits

The free Gemini 2.0 Flash model on OpenRouter:
- **Cost**: $0 (completely free)
- **Rate Limits**: Generous free tier (check OpenRouter docs)
- **Features**: Full model capabilities
- **Context**: Up to 2000 tokens output

## Switching Models

To use a different model, edit `lib/services/openrouter_ai_service.dart`:

```dart
static const String _model = 'google/gemini-2.0-flash-exp:free';
```

Available free models:
- `google/gemini-2.0-flash-exp:free` (Current - Recommended)
- `meta-llama/llama-3.2-3b-instruct:free`
- `microsoft/phi-3-mini-128k-instruct:free`
- `google/gemma-2-9b-it:free`

See: https://openrouter.ai/models for full list

## Security Notes

⚠️ **Important:**
1. **Never commit** `.env` file to version control
2. **Keep API key secret** - it's your personal credential
3. **Monitor usage** on OpenRouter dashboard
4. **Rotate keys** periodically for security

## Benefits Over Direct Gemini API

| Feature | Direct Gemini | OpenRouter + Gemini |
|---------|--------------|---------------------|
| Cost | Pay per use | Free tier available |
| Setup | Google Cloud account | Simple signup |
| Models | Gemini only | Multiple models |
| Switching | Requires code changes | Just change model name |
| Credits | $300 trial then pay | Free tier ongoing |

## Next Steps

After setup:
1. ✅ Test with a simple question
2. ✅ Try different grade levels
3. ✅ Test multi-language support
4. ✅ Try image-based questions (when implemented)
5. ✅ Monitor usage on OpenRouter dashboard

## Support

- **OpenRouter Docs**: https://openrouter.ai/docs
- **OpenRouter Discord**: https://discord.gg/openrouter
- **Model Info**: https://openrouter.ai/models
- **API Status**: https://status.openrouter.ai

## Summary

🎉 **OpenRouter Integration Complete!**

You now have:
- ✅ Free AI model configured (Gemini 2.0 Flash)
- ✅ Multi-language support
- ✅ Parent-friendly explanations
- ✅ Structured step-by-step responses
- ✅ Grade-level adaptation
- ✅ Easy model switching capability

**Time to setup:** ~5 minutes
**Cost:** $0 (free tier)
**Next step:** Add your API key to `.env` and rebuild!
