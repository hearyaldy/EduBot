# EduBot Screen Implementation Guide

## Overview

This document describes the implementation details for the three main screens in EduBot: Ask Question, Scan Homework, and Settings.

## Ask Question Screen

### Features Implemented
- **Text Input**: Multi-line text field for typing questions
- **Subject Selection**: Dropdown to categorize questions (Math, Science, English, etc.)
- **AI Integration**: Connects to OpenAI GPT-3.5 Turbo for explanations
- **Step-by-Step Display**: Shows detailed explanation steps with tips
- **Audio Support**: Text-to-speech for answers and explanations
- **Parent Tips**: Encouraging advice for parent-child learning
- **Real-World Examples**: Practical applications of concepts

### User Flow
1. Select subject (optional)
2. Type question in text field
3. Tap "Get Answer" button
4. View AI-generated explanation with steps
5. Listen to audio explanations
6. Save question to history

### Technical Details
- Uses `AIService` for OpenAI API calls
- Implements `AudioService.speakExplanation()` for TTS
- Integrates with `AppProvider` for state management
- Handles loading states and error management
- Responsive UI with modern Material Design 3

## Scan Homework Screen

### Features Implemented
- **Camera Integration**: Real-time camera preview
- **Permission Handling**: Requests camera permissions properly
- **Image Capture**: High-quality photo capture for OCR
- **Gallery Import**: Pick images from device gallery
- **OCR Processing**: Google ML Kit text recognition
- **Text Extraction**: Cleans and processes extracted text
- **AI Analysis**: Sends extracted text to AI for explanation
- **Visual Feedback**: Shows extracted text before processing

### User Flow
1. Grant camera permission
2. Position homework in camera viewfinder
3. Tap "Scan Now" or choose from gallery
4. View extracted text
5. Get AI explanation of the problem
6. Listen to audio explanations
7. Save to question history

### Technical Details
- Uses `camera` package for image capture
- Implements `permission_handler` for camera access
- Integrates `OCRService.extractTextFromXFile()`
- Connects to `AIService` for explanations
- Handles multiple image sources (camera/gallery)
- Error handling for OCR failures

## Settings Screen

### Features Implemented
- **Account Management**: Premium status, question history
- **Preferences**: Daily tips, language, theme settings
- **Audio Settings**: TTS controls, speech rate adjustment
- **Privacy & Data**: Privacy policy, data management
- **About Section**: App info, help center, feedback
- **Account Actions**: Sign out, delete account

### Sections Overview

#### Account Section
- Premium/Free status display
- Question usage counter
- Upgrade to Premium dialog
- Question history navigation

#### Preferences Section
- Daily tips toggle
- Language selection (placeholder for future i18n)
- Theme customization (placeholder)

#### Audio Settings
- TTS enable/disable
- Speech rate slider (0.1x to 1.0x)
- Audio test functionality

#### Privacy & Data
- Privacy policy links
- Terms of service
- Clear question history

#### About Section
- App version and information
- Help center access
- Feedback submission
- App store rating

### Technical Details
- Uses `Provider` for state management
- Implements modal dialogs for confirmations
- Handles external link opening (placeholder)
- Responsive card-based layout
- Proper error handling and user feedback

## Common Patterns

### Error Handling
All screens implement consistent error handling:
```dart
void _showSnackBar(String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
```

### Loading States
Consistent loading indicators with descriptive text:
```dart
if (_isLoading) ...[
  const CircularProgressIndicator(),
  Text('Processing your request...'),
]
```

### Modern UI Components
- Card-based layouts with 16px border radius
- Material Design 3 color scheme
- Proper spacing and typography
- Interactive feedback with animations

### Audio Integration
All screens support audio explanations:
```dart
Future<void> _playAudio(String text) async {
  try {
    await AudioService.speakExplanation(text);
  } catch (e) {
    _showSnackBar('Failed to play audio: ${e.toString()}', isError: true);
  }
}
```

## Security Considerations

### Camera Permissions
- Proper permission requests before camera access
- Graceful handling of permission denials
- Clear user messaging about permission requirements

### Data Handling
- Images processed locally with ML Kit
- No permanent storage of homework images
- Secure API communication with OpenAI

### Privacy Protection
- No collection of personal information from images
- Local OCR processing when possible
- Clear privacy controls in settings

## Performance Optimizations

### Camera Performance
- Uses `ResolutionPreset.high` for quality/performance balance
- Disables audio recording for camera
- Proper camera controller disposal

### Memory Management
- Disposes controllers and focus nodes properly
- Efficient image handling
- Minimal state retention

### Network Efficiency
- Optimized API calls to OpenAI
- Proper error handling for network issues
- Loading states for better UX

## Future Enhancements

### Ask Question Screen
- Voice input support
- Question suggestion prompts
- Offline mode with cached responses

### Scan Homework Screen
- Handwriting recognition
- Multi-page document scanning
- Batch processing of multiple problems

### Settings Screen
- Advanced theme customization
- Notification preferences
- Parental controls and restrictions

## Testing

All screens include:
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for complete flows
- Error scenario testing
- Performance testing for camera operations

## Dependencies

### Required Packages
- `camera`: Camera functionality
- `image_picker`: Gallery image selection
- `permission_handler`: Camera permissions
- `google_mlkit_text_recognition`: OCR processing
- `provider`: State management
- `http`: API communication

### Optional Packages (Future)
- `url_launcher`: External link opening
- `speech_to_text`: Voice input
- `flutter_tts`: Text-to-speech (already included)

This implementation provides a complete, production-ready experience for all three core screens of EduBot.
