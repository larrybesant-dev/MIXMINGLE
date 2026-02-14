# CI/CD Integration Script for Scheduled Runs
# This script can be called by Azure DevOps, Jenkins, or a local scheduler (e.g., Task Scheduler)

param(
    [switch]$DryRun,
    [string]$Branch = "main"
)

Write-Host "🚀 Starting CI/CD Pipeline for branch: $Branch"

if ($DryRun) {
    Write-Host "🔍 Dry run mode - no actual deployment"
    # Simulate pipeline steps without executing
    Write-Host "✅ Pipeline simulation complete"
    exit 0
}

# Run the actual pipeline
try {
    & .\run_pipeline.ps1
    Write-Host "✅ CI/CD Pipeline completed successfully"
} catch {
    Write-Host "❌ CI/CD Pipeline failed: $_"
    exit 1
}