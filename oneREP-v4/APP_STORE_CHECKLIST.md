# OneRepStrength - App Store Submission Checklist

## 1. Apple Developer Account
- [ ] Enroll in Apple Developer Program ($99/year): https://developer.apple.com/programs/
- [ ] Set up App Store Connect: https://appstoreconnect.apple.com
- [ ] Create App ID in Apple Developer portal
- [ ] Create provisioning profiles for Distribution

## 2. App Information (App Store Connect)

### Basic Info
- [ ] App Name: "OneRepStrength" (check availability)
- [ ] Subtitle: "HIT Workout Timer & Tracker"
- [ ] Primary Category: Health & Fitness
- [ ] Secondary Category: Lifestyle
- [ ] Age Rating: 4+ (no objectionable content)

### Description (4000 chars max)
```
OneRepStrength is the ultimate High-Intensity Training (HIT) companion designed for efficient, science-based strength training.

Built on Dr. Ellington Darden's proven research, this app guides you through slow, controlled repetitions that maximize muscle engagement while minimizing injury risk.

KEY FEATURES:
• Guided Timer Phases - Prep, positioning, eccentric, concentric, and final eccentric
• Voice Control - Hands-free commands via earbuds
• Exercise Library - Pre-loaded with common machine exercises
• Progress Tracking - Log weights, track PRs, view history
• Custom Routines - Create and save your workout templates
• Apple Watch Support - Control your workout from your wrist
• Partner Mode - Workout with a training partner

PERFECT FOR:
• Busy professionals who want efficient 30-minute workouts
• Adults 50+ focused on injury prevention
• Anyone recovering from traditional weight training injuries
• HIT/SuperSlow training enthusiasts

Train smarter, not longer. Get stronger with just one intense rep per exercise.
```

### Keywords (100 chars)
```
HIT,strength,workout,timer,slow training,fitness,gym,weights,exercise,SuperSlow,Darden
```

### Privacy Policy URL
- [ ] Create privacy policy (required for apps collecting data)
- [ ] Host at: https://onerepstrength.com/privacy
- [ ] Must explain: data collected, speech recognition usage, health data

### Support URL
- [ ] https://onerepstrength.com/support (or GitHub repo link)

## 3. Screenshots Required

### iPhone (6.7" - iPhone 15 Pro Max)
- [ ] Screenshot 1: Main workout screen with exercise cards
- [ ] Screenshot 2: Timer view in action (eccentric phase)
- [ ] Screenshot 3: Rest period with next exercise preview
- [ ] Screenshot 4: History/calendar view
- [ ] Screenshot 5: Settings/customization options

### iPhone (6.5" - iPhone 11 Pro Max) - Optional but recommended
- Same screenshots as above

### iPad (12.9" - iPad Pro) - If supporting iPad
- [ ] Same screenshots, adapted for iPad layout

### Apple Watch
- [ ] Watch app main screen
- [ ] Watch app during exercise

## 4. App Icon
- [ ] 1024x1024px PNG (no alpha/transparency)
- [ ] No rounded corners (Apple adds them)
- [ ] Design suggestion: Dumbbell with timer/stopwatch element

## 5. Privacy & Permissions

### Info.plist Keys (Already Added)
- [x] NSMicrophoneUsageDescription - Voice commands
- [x] NSSpeechRecognitionUsageDescription - Speech recognition

### May Need to Add
- [ ] NSHealthShareUsageDescription - If integrating HealthKit
- [ ] NSHealthUpdateUsageDescription - If writing to HealthKit
- [ ] NSCameraUsageDescription - If adding form check video

### App Privacy Details (App Store Connect)
Fill out privacy nutrition labels:
- [ ] Data Used to Track You: None
- [ ] Data Linked to You: Exercise data, workout logs (stored locally)
- [ ] Data Not Linked to You: Usage analytics (if using)

## 6. Technical Requirements

### Minimum iOS Version
- [ ] Set to iOS 17.0 (current setting)
- Consider iOS 16.0 for wider reach

### Device Support
- [x] iPhone (Universal)
- [x] Apple Watch
- [ ] iPad (verify layout works)

### Code Signing
- [ ] Archive with Distribution certificate
- [ ] Use App Store provisioning profile

### TestFlight
- [ ] Upload build to TestFlight first
- [ ] Test on real devices
- [ ] Invite beta testers (up to 10,000)

## 7. Review Guidelines Compliance

### Common Rejection Reasons to Avoid
- [ ] App must be complete and functional
- [ ] No placeholder content
- [ ] No crashes or bugs
- [ ] Privacy policy must be accurate
- [ ] All features must work as described
- [ ] In-app purchases must use Apple's system

### Health & Fitness Specific
- [ ] Don't make medical claims
- [ ] Include disclaimer: "Consult physician before starting exercise"
- [ ] Don't claim to diagnose or treat conditions

## 8. Monetization (Choose One)

### Option A: Free
- No revenue, but builds user base

### Option B: Paid Upfront ($2.99-$4.99)
- Simple, one-time purchase
- Good for niche fitness apps

### Option C: Freemium
- Free with basic features
- Pro upgrade via In-App Purchase
- Pro features: Commander voices, advanced analytics, cloud sync

### Option D: Subscription
- Monthly/yearly recurring
- Best for ongoing content/features
- Requires more maintenance

## 9. Pre-Submission Checklist

### Code
- [ ] Remove all debug/test code
- [ ] Remove print statements
- [ ] Test on multiple device sizes
- [ ] Test offline functionality
- [ ] Test voice commands in noisy environment
- [ ] Verify all UserDefaults keys are correct
- [ ] Test fresh install (no stored data)

### Assets
- [ ] All images are high resolution
- [ ] No placeholder images
- [ ] App icon in all required sizes
- [ ] Launch screen configured

### Metadata
- [ ] Description is accurate
- [ ] Screenshots show actual app
- [ ] Keywords are relevant (no competitor names)
- [ ] Contact info is valid

## 10. Post-Submission

### Review Timeline
- Typically 24-48 hours for first review
- May take longer if issues found

### If Rejected
- Read rejection reason carefully
- Fix issues promptly
- Reply in Resolution Center if unclear
- Resubmit when ready

### After Approval
- [ ] Set release date (immediate or scheduled)
- [ ] Monitor crash reports in Xcode Organizer
- [ ] Respond to user reviews
- [ ] Plan updates based on feedback

## 11. Optional Enhancements Before Launch

### Recommended
- [ ] Add HealthKit integration (write workouts)
- [ ] Add Widget for quick access
- [ ] Add Siri Shortcuts integration
- [ ] Localize for other languages

### Nice to Have
- [ ] iCloud sync for data backup
- [ ] Social sharing of achievements
- [ ] Workout reminders via notifications

## 12. Marketing Checklist

- [ ] Create App Store preview video (15-30 seconds)
- [ ] Set up onerepstrength.com website
- [ ] Create social media accounts
- [ ] Prepare press release
- [ ] Reach out to fitness bloggers/reviewers

---

## Quick Start Commands

### Archive for App Store
```bash
# In Xcode: Product > Archive
# Or via command line:
xcodebuild -project OneRepStrength.xcodeproj \
  -scheme OneRepStrength \
  -configuration Release \
  -archivePath ./build/OneRepStrength.xcarchive \
  archive
```

### Export for App Store
```bash
xcodebuild -exportArchive \
  -archivePath ./build/OneRepStrength.xcarchive \
  -exportPath ./build/AppStore \
  -exportOptionsPlist ExportOptions.plist
```

### Upload to App Store Connect
- Use Xcode Organizer (recommended)
- Or Transporter app
- Or altool command line

---

## Questions?

Review Apple's official guidelines:
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- App Store Connect Help: https://help.apple.com/app-store-connect/
