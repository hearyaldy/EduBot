# EduBot Theme Guide

## Modern Color Palette

EduBot uses a modern, accessible color palette based on the primary color `#2563EB` (blue-600) with carefully selected complementary colors.

### Primary Colors
- **Primary Blue**: `#2563EB` - Main brand color
- **Primary Light**: `#3B82F6` - Lighter variant for hover states
- **Primary Dark**: `#1D4ED8` - Darker variant for pressed states  
- **Primary Surface**: `#EFF6FF` - Very light blue for background elements

### Accent Colors
- **Success/Accent**: `#10B981` - Modern emerald green
- **Warning**: `#F59E0B` - Modern amber
- **Error**: `#EF4444` - Modern red
- **Info**: `#06B6D4` - Modern cyan

### Neutral Colors
- **Text Primary**: `#111827` - Rich black for main text
- **Text Secondary**: `#6B7280` - Medium gray for secondary text
- **Text Tertiary**: `#9CA3AF` - Light gray for placeholder text
- **Background**: `#F9FAFB` - Off-white app background
- **Surface**: `#FFFFFF` - Pure white for cards and containers
- **Surface Variant**: `#F3F4F6` - Light gray for input fields
- **Divider**: `#E5E7EB` - Modern gray for separators
- **Border**: `#D1D5DB` - Medium gray for borders

## Design System Features

### Material Design 3
- Uses Material Design 3 (`useMaterial3: true`)
- Follows Material color system with proper contrast ratios
- Supports dynamic color schemes

### Modern Components
- **Cards**: 16px border radius with subtle shadows
- **Buttons**: 12px border radius with proper padding and typography
- **Input Fields**: 12px border radius with modern fill colors
- **Icons**: Consistent sizing and color usage

### Typography
- **Font Weight**: Uses w600-w700 for headings, w500 for buttons
- **Letter Spacing**: 0.5px for improved readability
- **Hierarchy**: Clear distinction between display, headline, title, and body text

### Accessibility
- **Color Contrast**: All colors meet WCAG 2.1 AA standards
- **Touch Targets**: Minimum 44px touch targets for interactive elements
- **Focus Indicators**: Clear focus states for keyboard navigation

### Modern Shadows & Effects
- **Card Shadow**: Subtle blue-tinted shadows using primary color
- **Button Elevation**: Modern depth with colored shadows
- **Gradients**: Available for special elements (primary gradient)

## Usage Examples

### Using Theme Colors in Code
```dart
// Primary brand color
color: Theme.of(context).colorScheme.primary

// Success state
color: AppTheme.success

// Text colors
color: AppTheme.textPrimary
color: AppTheme.textSecondary

// Background colors
backgroundColor: Theme.of(context).colorScheme.surface
```

### Custom Gradients
```dart
// Primary gradient for special elements
decoration: BoxDecoration(
  gradient: AppTheme.primaryGradient,
)
```

### Modern Shadows
```dart
// Modern card shadow
BoxShadow shadow = AppTheme.modernShadow;

// Subtle shadow for floating elements
BoxShadow shadow = AppTheme.subtleShadow;
```

## Color Accessibility

All colors have been tested for accessibility:
- **Normal text**: 4.5:1 contrast ratio minimum
- **Large text**: 3:1 contrast ratio minimum
- **Interactive elements**: Clear focus and hover states
- **Error states**: Sufficient contrast for readability

## Dark Mode Support

The theme is designed to be extended with a dark mode variant:
- Light mode uses the colors defined above
- Dark mode colors can be added following the same naming convention
- Material Design 3 provides automatic dark mode color generation

## Migration from Old Theme

### Breaking Changes
- Updated primary color from `#2196F3` to `#2563EB`
- Replaced deprecated `withOpacity()` with `withValues(alpha:)`
- Updated `surfaceVariant` to `surfaceContainerHighest`
- Removed deprecated `background` color property

### Benefits
- More modern and professional appearance
- Better accessibility and contrast ratios
- Consistent with current design trends
- Future-proof with Material Design 3
- Enhanced user experience with improved visual hierarchy
