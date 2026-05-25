# =============================================================================
#  test-automations.ps1
#  Tests the automation-service API end-to-end.
#
#  Prerequisites:
#    1. docker compose up -d  (stack running)
#    2. A registered user (register via gateway first)
#
#  Usage:
#    .\scripts\test-automations.ps1
# =============================================================================

$GATEWAY = "http://localhost:8080"
$EMAIL   = "test@home.local"
$PASS    = "Test123!"

Write-Host "=== 1. Login ===" -ForegroundColor Cyan
$login = curl -s "$GATEWAY/api/auth/login" `
  -H "Content-Type: application/json" `
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" | ConvertFrom-Json

if (-not $login.token) {
  Write-Host "Login failed. Try registering first:" -ForegroundColor Yellow
  Write-Host "curl -X POST $GATEWAY/api/auth/register -H 'Content-Type: application/json' -d '{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"homeName\":\"My Home\"}'"
  exit 1
}

$TOKEN = $login.token
$HOME_ID = $login.homeId
Write-Host "Logged in. Home: $HOME_ID" -ForegroundColor Green

$AUTH = @{ "X-Authorization" = "Bearer $TOKEN" }

# ── Automations ───────────────────────────────────────────────────────────────

Write-Host "`n=== 2. Create SCHEDULE automation ===" -ForegroundColor Cyan
$schedule = curl -s -X POST "$GATEWAY/api/automations" `
  -H "Content-Type: application/json" `
  -H @AUTH `
  -d '{
    "name": "Goodnight lights",
    "description": "Turn off all lights at 10 PM",
    "triggerType": "SCHEDULE",
    "actionType": "DEVICE_COMMAND",
    "rules": [{
      "conditionJson": {"cron": "0 22 * * *", "timezone": "UTC"},
      "actionJson":   {"deviceId": "00000000-0000-0000-0000-000000000001", "method": "setPower", "params": {"state": false}},
      "sortOrder": 0
    }]
  }' | ConvertFrom-Json
$AUTO_ID = $schedule.id
Write-Host "Created automation: $AUTO_ID" -ForegroundColor Green

Write-Host "`n=== 3. List automations ===" -ForegroundColor Cyan
curl -s "$GATEWAY/api/automations" -H @AUTH | ConvertFrom-Json | ConvertTo-Json -Compress

Write-Host "`n=== 4. Get single automation ===" -ForegroundColor Cyan
curl -s "$GATEWAY/api/automations/$AUTO_ID" -H @AUTH | ConvertFrom-Json | ConvertTo-Json -Compress

Write-Host "`n=== 5. Toggle enabled/disabled ===" -ForegroundColor Cyan
curl -s -X PATCH "$GATEWAY/api/automations/$AUTO_ID/toggle" -H @AUTH | ConvertFrom-Json | ConvertTo-Json -Compress

Write-Host "`n=== 6. Create SENSOR_THRESHOLD automation (synced to TB) ===" -ForegroundColor Cyan
$sensor = curl -s -X POST "$GATEWAY/api/automations" `
  -H "Content-Type: application/json" `
  -H @AUTH `
  -d '{
    "name": "High temp alert",
    "description": "Notify when temperature exceeds 30C",
    "triggerType": "SENSOR_THRESHOLD",
    "actionType": "NOTIFICATION",
    "rules": [{
      "conditionJson": {"metric": "temperature", "op": "gt", "value": 30},
      "actionJson":   {"title": "🔥 High temperature", "body": "Temperature exceeded 30C"},
      "sortOrder": 0
    }]
  }' | ConvertFrom-Json
Write-Host "tbRuleNodeId: $($sensor.tbRuleNodeId)" -ForegroundColor Green

# ── Scenes ────────────────────────────────────────────────────────────────────

Write-Host "`n=== 7. Create scene ===" -ForegroundColor Cyan
$scene = curl -s -X POST "$GATEWAY/api/scenes" `
  -H "Content-Type: application/json" `
  -H @AUTH `
  -d '{
    "name": "Movie mode",
    "iconKey": "movie",
    "favorite": true,
    "actions": [
      {"deviceId": "00000000-0000-0000-0000-000000000001", "commandJson": {"method": "setPower", "params": {"state": false}}, "delayMs": 0,    "sortOrder": 0},
      {"deviceId": "00000000-0000-0000-0000-000000000002", "commandJson": {"method": "setBrightness", "params": {"value": 20}},  "delayMs": 500, "sortOrder": 1}
    ]
  }' | ConvertFrom-Json
$SCENE_ID = $scene.id
Write-Host "Created scene: $SCENE_ID" -ForegroundColor Green

Write-Host "`n=== 8. List favorite scenes ===" -ForegroundColor Cyan
curl -s "$GATEWAY/api/scenes/favorites" -H @AUTH | ConvertFrom-Json | ConvertTo-Json -Compress

Write-Host "`n=== 9. Activate scene ===" -ForegroundColor Cyan
curl -s -X POST "$GATEWAY/api/scenes/$SCENE_ID/activate" -H @AUTH | ConvertFrom-Json | ConvertTo-Json -Compress

# ── Cleanup ───────────────────────────────────────────────────────────────────

Write-Host "`n=== 10. Delete automation ===" -ForegroundColor Cyan
curl -s -X DELETE "$GATEWAY/api/automations/$AUTO_ID" -H @AUTH
Write-Host "Deleted: $AUTO_ID"

Write-Host "`n=== 11. Delete scene ===" -ForegroundColor Cyan
curl -s -X DELETE "$GATEWAY/api/scenes/$SCENE_ID" -H @AUTH
Write-Host "Deleted: $SCENE_ID"

Write-Host "`nAll tests completed!" -ForegroundColor Green
