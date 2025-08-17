# 🔑 Step-by-Step Keystore Generation Commands

## Run These Commands in Your Terminal

### Step 1: Navigate to the Android Directory
```bash
cd /Users/hearyhealdysairin/Documents/Flutter/edubot/android
```

### Step 2: Generate the Keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Step 3: Respond to the Prompts

When you run the command above, you'll see these prompts. Here are example responses:

#### 🔒 Keystore Password
```
Enter keystore password: [Type a strong password, minimum 12 characters]
Re-enter new password: [Type the same password again]
```
**Example strong password**: `EduBot2024@Secure!`

#### 🔑 Key Password  
```
Enter key password for <upload>
	(RETURN if same as keystore password): [Press ENTER to use same password]
```

#### 👤 Personal Information
```
What is your first and last name?
  [Unknown]:  John Smith

What is the name of your organizational unit?
  [Unknown]:  Developer

What is the name of your organization?
  [Unknown]:  EduBot Team

What is the name of your City or Locality?
  [Unknown]:  San Francisco

What is the name of your State or Province?
  [Unknown]:  California

What is the two-letter country code for this unit?
  [Unknown]:  US

Is CN=John Smith, OU=Developer, O=EduBot Team, L=San Francisco, ST=California, C=US correct?
  [no]:  yes
```

### Step 4: Create key.properties File
```bash
cp key.properties.template key.properties
```

### Step 5: Edit key.properties
Open `android/key.properties` and replace with your actual values:
```properties
storePassword=EduBot2024@Secure!
keyPassword=EduBot2024@Secure!
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 6: Test Release Build
```bash
cd ..
flutter build appbundle --release
```

## 🎯 Success Indicators

You'll know it worked when you see:
- `✓ Built build/app/outputs/bundle/release/app-release.aab`
- File size around 20-50MB
- No signing errors

## ⚠️ Remember

- **SAVE** your passwords securely
- **BACKUP** the keystore file
- **NEVER** commit these files to git