# =============================================================================
#  rebuild-automation.ps1
#  Builds and deploys the updated automation-service.
#
#  Run from the repo root (F:\flutter_thingsboard_app)
# =============================================================================

Write-Host "1. Building JAR..." -ForegroundColor Cyan
Push-Location automation-service
mvn clean package -DskipTests
if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
Pop-Location

Write-Host "2. Rebuilding Docker image..." -ForegroundColor Cyan
docker compose build automation-service

Write-Host "3. Restarting service..." -ForegroundColor Cyan
docker compose up -d automation-service

Write-Host "4. Waiting for health check..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
curl -s http://localhost:8084/health | ConvertFrom-Json | ConvertTo-Json
