package com.smarthome.automation.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smarthome.automation.domain.ActionType;
import com.smarthome.automation.domain.AutomationRule;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class ActionExecutor {

    private final RestClient   restClient;
    private final ObjectMapper objectMapper;

    @Value("${services.device-url:http://device-service:8082}")
    private String deviceServiceUrl;

    @Value("${services.notification-url:http://notification-service:8085}")
    private String notificationServiceUrl;

    public void executeAll(
        List<AutomationRule> rules,
        ActionType           actionType,
        UUID                 homeId,
        Map<String, Object>  triggerData
    ) {
        rules.forEach(rule -> {
            try {
                execute(rule.getActionJson(), actionType, homeId, triggerData);
            } catch (Exception e) {
                log.error("Action execution failed for rule {}: {}",
                    rule.getId(), e.getMessage(), e);
            }
        });
    }

    @SuppressWarnings("unchecked")
    public void execute(
        Map<String, Object>  action,
        ActionType           actionType,
        UUID                 homeId,
        Map<String, Object>  triggerData
    ) {
        switch (actionType) {
            case DEVICE_COMMAND -> executeDeviceCommand(action);
            case SCENE_ACTIVATE -> executeSceneActivation(action, homeId);
            case NOTIFICATION   -> executeNotification(action, homeId, triggerData);
            case WEBHOOK        -> executeWebhook(action);
        }
    }

    private void executeDeviceCommand(Map<String, Object> action) {
        final String deviceId = (String) action.get("deviceId");
        final String method   = (String) action.get("method");
        @SuppressWarnings("unchecked")
        final Map<String, Object> params =
            (Map<String, Object>) action.getOrDefault("params", Map.of());

        if (deviceId == null || method == null) {
            log.warn("Device command action missing deviceId or method: {}", action);
            return;
        }

        restClient.post()
            .uri(deviceServiceUrl + "/api/internal/devices/{id}/command", deviceId)
            .body(Map.of("method", method, "params", params))
            .retrieve()
            .toBodilessEntity();

        log.info("Executed automation command '{}' on device {}", method, deviceId);
    }

    private void executeSceneActivation(Map<String, Object> action, UUID homeId) {
        final String sceneId = (String) action.get("sceneId");
        if (sceneId == null) {
            log.warn("Scene activate action missing sceneId: {}", action);
            return;
        }

        restClient.post()
            .uri("http://automation-service:8084/api/internal/automation/scenes/{id}/activate?homeId={homeId}", sceneId, homeId)
            .retrieve()
            .toBodilessEntity();
    }

    @SuppressWarnings("unchecked")
    private void executeNotification(
        Map<String, Object> action,
        UUID homeId,
        Map<String, Object> triggerData
    ) {
        final String       title   = (String) action.getOrDefault("title", "Automation triggered");
        String             body    = (String) action.getOrDefault("body", "");
        final List<String> userIds = (List<String>) action.get("userIds");

        for (var entry : triggerData.entrySet()) {
            body = body.replace("{{" + entry.getKey() + "}}", entry.getValue().toString());
        }

        restClient.post()
            .uri(notificationServiceUrl + "/api/internal/notify")
            .body(Map.of(
                "title",   title,
                "body",    body,
                "homeId",  homeId.toString(),
                "userIds", userIds != null ? userIds : List.of(),
                "type",    "automation"
            ))
            .retrieve()
            .toBodilessEntity();

        log.info("Sent automation notification: '{}'", title);
    }

    private void executeWebhook(Map<String, Object> action) {
        final String url    = (String) action.get("url");
        final String method = (String) action.getOrDefault("method", "POST");
        @SuppressWarnings("unchecked")
        final Map<String, Object> payload =
            (Map<String, Object>) action.getOrDefault("payload", Map.of());

        if (url == null) { log.warn("Webhook action missing url"); return; }

        try {
            if ("POST".equalsIgnoreCase(method)) {
                restClient.post().uri(url).body(payload).retrieve().toBodilessEntity();
            } else {
                restClient.get().uri(url).retrieve().toBodilessEntity();
            }
            log.info("Executed webhook {} {}", method, url);
        } catch (Exception e) {
            log.error("Webhook failed [{} {}]: {}", method, url, e.getMessage());
        }
    }
}
