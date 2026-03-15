# PowerShell script to add GitHub secrets using GitHub CLI
# Make sure you have gh CLI installed and authenticated
# Replace the values with your actual secrets

$repo = "LARRY/MIXMINGLE"  # Change if your repo is under a different user/org

$secrets = @{
    GITHUB_TOKEN = "<your_github_token>"
    ANDROID_KEYSTORE_BASE64 = "<your_android_keystore_base64>"
    ANDROID_KEYSTORE_PASSWORD = "<your_android_keystore_password>"
    ANDROID_KEY_PASSWORD = "<your_android_key_password>"
    ANDROID_KEY_ALIAS = "<your_android_key_alias>"
    FIREBASE_SERVICE_ACCOUNT = "<your_firebase_service_account>"
    PLAY_STORE_SERVICE_ACCOUNT = "<your_play_store_service_account>"
    IOS_CERTIFICATES_P12 = "<your_ios_certificates_p12>"
    IOS_CERTIFICATES_PASSWORD = "<your_ios_certificates_password>"
    APP_STORE_CONNECT_ISSUER_ID = "<your_app_store_connect_issuer_id>"
    APP_STORE_CONNECT_KEY_ID = "<your_app_store_connect_key_id>"
    APP_STORE_CONNECT_PRIVATE_KEY = "<your_app_store_connect_private_key>"
    GCP_SA_KEY = "<your_gcp_sa_key>"
    FIREBASE_TOKEN = "<your_firebase_token>"
    CODECOV_TOKEN = "<your_codecov_token>"
    PLAY_STORE_SERVICE_ACCOUNT_JSON = "<your_play_store_service_account_json>"
    APP_STORE_CONNECT_API_KEY_ID = "<your_app_store_connect_api_key_id>"
    APP_STORE_CONNECT_API_PRIVATE_KEY = "<your_app_store_connect_api_private_key>"
}

foreach ($name in $secrets.Keys) {
    $value = $secrets[$name]
    if ($value -ne "" -and $value -ne "<your_" + $name.ToLower() + ">") {
        Write-Host "Adding secret: $name"
        gh secret set $name -b"$value" -R $repo
    } else {
        Write-Host "Skipping $name: No value set"
    }
}
