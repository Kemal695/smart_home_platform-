package com.smarthome.automation.controller;

import com.smarthome.automation.service.AutomationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/internal/automation")
@RequiredArgsConstructor
public class InternalAutomationController {

    private final AutomationService automationService;

    @PostMapping("/trigger")
    public ResponseEntity<Void> triggerFromThingsBoard(@RequestBody Map<String, Object> payload) {
        var automationId = UUID.fromString((String) payload.get("automationId"));
        var tbDeviceId   = (String) payload.get("tbDeviceId");
        @SuppressWarnings("unchecked")
        var telemetry    = (Map<String, Object>) payload.getOrDefault("telemetry", Map.of());

        log.info("Internal trigger for automation {} from TB device {}", automationId, tbDeviceId);
        automationService.triggerFromThingsBoard(automationId, tbDeviceId, telemetry);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/scenes/{id}/activate")
    public ResponseEntity<Void> activateScene(@PathVariable UUID id, @RequestParam UUID homeId) {
        automationService.activateScene(homeId, id);
        return ResponseEntity.ok().build();
    }
}
