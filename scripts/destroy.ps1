# AWS Traffic Prediction System Destruction Script (PowerShell)
# This script destroys the entire infrastructure

Write-Host "⚠️  WARNING: This will destroy all AWS resources!" -ForegroundColor Red
Write-Host "This action cannot be undone."
Write-Host ""
$Confirm = Read-Host "Are you sure you want to continue? (yes/no)"

if ($Confirm -ne "yes") {
    Write-Host "❌ Destruction cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host "🗑️  Starting infrastructure destruction..." -ForegroundColor Yellow

# Change to terraform directory
Set-Location terraform

# Destroy infrastructure
Write-Host "🏗️  Destroying Terraform infrastructure..." -ForegroundColor Yellow
terraform destroy -auto-approve

Write-Host "✅ Infrastructure destroyed successfully" -ForegroundColor Green

# Clean up local files
Write-Host "🧹 Cleaning up local files..." -ForegroundColor Yellow
Set-Location ".."
Remove-Item -Recurse -Force "lambda_packages" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "sagemaker_packages" -ErrorAction SilentlyContinue
Remove-Item -Force "deployment-config.json" -ErrorAction SilentlyContinue
Remove-Item -Force "frontend/.env" -ErrorAction SilentlyContinue

Write-Host "🎉 Cleanup completed successfully!" -ForegroundColor Green
Write-Host "All AWS resources have been destroyed and local files cleaned up."
