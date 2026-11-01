/// Firebase Setup Documentation
///
/// ## SDK Firebase Architecture
///
/// The Qubrix has its own Firebase configuration for Remote Config.
/// This is separate from the host app's Firebase configuration.
///
/// ## Two Firebase Configurations
///
/// ### 1. SDK's Firebase (Qubrix's own Firebase)
/// - Used by the SDK for Remote Config (fetching HuggingFace model URL)
/// - Configured in the SDK's Firebase project
/// - The SDK initializes this automatically
/// - Host app doesn't need to configure this
/// - Placeholders are in `SdkFirebaseOptions` (in the SDK)
///
/// ### 2. Host App's Firebase (User's own Firebase)
/// - Used by the host app for its own features (analytics, auth, etc.)
/// - Configured in the host app's Firebase project
/// - The host app configures this for its own needs
/// - The host app may or may not have Firebase
///
/// ## SDK Firebase is Required for Remote Config
///
/// The SDK uses Firebase Remote Config to fetch the HuggingFace model URL.
/// This is the SDK's own Firebase, not the host app's.
///
/// Even if the host app has no Firebase, the SDK's Firebase handles
/// the Remote Config need.
///
/// ## Setup the SDK's Firebase
///
/// 1. Create a Firebase project for the SDK at https://console.firebase.google.com
/// 2. Add Android and iOS apps to the project
/// 3. Download google-services.json (Android) and GoogleService-Info.plist (iOS)
/// 4. Replace the placeholder values in the SDK's SdkFirebaseOptions
///
/// ## Host App May Have Its Own Firebase
///
/// The host app (WhatsApp, Instagram, or any custom app) may have its own
/// Firebase configuration for its own features. This is completely separate
/// from the SDK's Firebase.
///
/// ## If Host App Has Firebase
///
/// If the host app already has Firebase with Remote Config configured for
/// the model URL, the SDK can optionally use the host app's Firebase instead
/// of its own. This is configured in SdkFirebaseInitializer.
///
/// ## If Host App Has No Firebase
///
/// If the host app has no Firebase at all, the SDK's Firebase works
/// independently. The SDK initializes its own Firebase app for Remote Config.
///
/// ## Model URL Configuration in Firebase Remote Config
///
/// In the SDK's Firebase project, set up a Remote Config parameter:
/// - Parameter name: hf_model_url
/// - Value: https://huggingface.co/<owner>/<repo>
///
/// Example: https://huggingface.co/facebook/opt-1.3b
///
/// ## Example App Firebase
///
/// The example app in this project uses the SDK's Firebase. It doesn't need
/// its own Firebase for the model download feature. However, if you want to
/// add Firebase features to the example app (analytics, etc.), you can add
/// the host app's Firebase config separately.
///
/// ## User Flow in Example App
///
/// 1. User opens app → sees "Download Model" button (cloud icon)
/// 2. User taps "Download Model"
/// 3. App uses SDK's Firebase Remote Config to get model URL
/// 4. SDK extracts repo ID from URL
/// 5. SDK downloads model from HuggingFace
/// 6. Model verified → loaded → user can run tasks
///
/// The user never selects a model - it's a background task.
/// The model URL comes from the SDK's Firebase Remote Config.
library firebase_setup;
