function Run-AppDeploy {
    Write-Log "Deploying to Firebase Hosting..."
    firebase deploy --only hosting
    Write-Log "Deployment complete."
}