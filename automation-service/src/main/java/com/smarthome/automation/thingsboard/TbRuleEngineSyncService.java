package com.smarthome.automation.thingsboard;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smarthome.automation.domain.Automation;
import com.smarthome.automation.domain.AutomationRule;
import com.smarthome.automation.domain.TriggerType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class TbRuleEngineSyncService {

    private final RestClient     restClient;
    private final TbAuthClient   tbAuth;
    private final ObjectMapper   objectMapper;

    @Value("${thingsboard.base-url}")
    private String tbBaseUrl;

    @Value("${app.backend-internal-url:http://automation-service:8084}")
    private String backendUrl;

    public String syncAutomation(Automation automation) {
        if (!needsTbSync(automation)) {
            log.debug("Automation {} does not need TB sync (type={})",
                automation.getId(), automation.getTriggerType());
            return null;
        }

        if (automation.getTbRuleChainId() != null) {
            updateRuleChain(automation);
            return automation.getTbRuleChainId();
        } else {
            return createRuleChain(automation);
        }
    }

    public void setEnabled(String tbRuleChainId, boolean enabled) {
        if (tbRuleChainId == null) return;

        try {
            tbClient().post()
                .uri(tbBaseUrl + "/api/ruleChain/{id}/metadata", tbRuleChainId)
                .body(Map.of("debugMode", !enabled))
                .retrieve()
                .toBodilessEntity();

            log.info("TB rule chain {} set enabled={}", tbRuleChainId, enabled);
        } catch (Exception e) {
            log.error("Failed to toggle TB rule chain {}: {}", tbRuleChainId, e.getMessage());
        }
    }

    public void deleteRuleChain(String tbRuleChainId) {
        if (tbRuleChainId == null) return;

        try {
            tbClient().delete()
                .uri(tbBaseUrl + "/api/ruleChain/{id}", tbRuleChainId)
                .retrieve()
                .toBodilessEntity();

            log.info("TB rule chain {} deleted", tbRuleChainId);
        } catch (Exception e) {
            log.error("Failed to delete TB rule chain {}: {}", tbRuleChainId, e.getMessage());
        }
    }

    private boolean needsTbSync(Automation automation) {
        return automation.getTriggerType() == TriggerType.DEVICE_STATE
            || automation.getTriggerType() == TriggerType.SENSOR_THRESHOLD
            || automation.getTriggerType() == TriggerType.SUNRISE_SUNSET;
    }

    @SuppressWarnings("unchecked")
    private String createRuleChain(Automation automation) {
        try {
            var chainBody = Map.of(
                "name",      "SmartHome: " + automation.getName(),
                "debugMode", false,
                "type",      "CORE"
            );

            var chainResp = tbClient().post()
                .uri(tbBaseUrl + "/api/ruleChain")
                .body(chainBody)
                .retrieve()
                .body(Map.class);

            if (chainResp == null) throw new RuntimeException("TB returned null for rule chain creation");

            var chainIdMap = (Map<String, String>) chainResp.get("id");
            var chainId    = chainIdMap.get("id");

            var metadata = buildRuleChainMetadata(automation, chainId);
            tbClient().post()
                .uri(tbBaseUrl + "/api/ruleChain/metadata")
                .body(metadata)
                .retrieve()
                .toBodilessEntity();

            log.info("Created TB rule chain {} for automation {}", chainId, automation.getId());
            return chainId;

        } catch (Exception e) {
            log.error("Failed to create TB rule chain for automation {}: {}",
                automation.getId(), e.getMessage(), e);
            return null;
        }
    }

    private void updateRuleChain(Automation automation) {
        try {
            var metadata = buildRuleChainMetadata(automation, automation.getTbRuleChainId());
            tbClient().post()
                .uri(tbBaseUrl + "/api/ruleChain/metadata")
                .body(metadata)
                .retrieve()
                .toBodilessEntity();

            log.info("Updated TB rule chain {} for automation {}",
                automation.getTbRuleChainId(), automation.getId());
        } catch (Exception e) {
            log.error("Failed to update TB rule chain: {}", e.getMessage(), e);
        }
    }

    private Map<String, Object> buildRuleChainMetadata(Automation automation, String chainId) {
        var filterScript = buildFilterScript(automation.getRules());
        var webhookUrl   = buildWebhookUrl(automation);

        return Map.of(
            "ruleChainId", Map.of("id", chainId, "entityType", "RULE_CHAIN"),
            "firstNodeIndex", 0,
            "nodes", List.of(
                Map.of(
                    "type", "org.thingsboard.rule.engine.flow.TbRuleChainInputNode",
                    "name", "Input",
                    "debugMode", false,
                    "configuration", Map.of(),
                    "additionalInfo", Map.of("layoutX", 100, "layoutY", 200)
                ),
                Map.of(
                    "type", "org.thingsboard.rule.engine.filter.TbScriptFilterNode",
                    "name", "Condition Filter",
                    "debugMode", false,
                    "configuration", Map.of(
                        "scriptLang", "JS",
                        "jsScript",   filterScript
                    ),
                    "additionalInfo", Map.of("layoutX", 350, "layoutY", 200)
                ),
                Map.of(
                    "type", "org.thingsboard.rule.engine.rest.TbRestApiCallNode",
                    "name", "Trigger Backend",
                    "debugMode", false,
                    "configuration", Map.of(
                        "restEndpointUrlPattern", webhookUrl,
                        "requestMethod",          "POST",
                        "headers",                Map.of("Content-Type", "application/json"),
                        "useSimpleClientHttpFactory", false,
                        "maxParallelRequestsCount", 10,
                        "bodyTemplate",          buildWebhookBody(automation)
                    ),
                    "additionalInfo", Map.of("layoutX", 600, "layoutY", 200)
                )
            ),
            "connections", List.of(
                Map.of("fromIndex", 0, "toIndex", 1, "type", "Success"),
                Map.of("fromIndex", 1, "toIndex", 2, "type", "True")
            ),
            "ruleChainConnections", List.of()
        );
    }

    private String buildFilterScript(List<AutomationRule> rules) {
        if (rules.isEmpty()) return "return true;";

        var conditions = rules.stream()
            .map(r -> buildSingleConditionScript(r.getConditionJson()))
            .filter(s -> !s.isBlank())
            .toList();

        if (conditions.isEmpty()) return "return true;";

        return "return " + String.join(" || ", conditions) + ";";
    }

    @SuppressWarnings("unchecked")
    private String buildSingleConditionScript(Map<String, Object> condition) {
        final String type   = (String) condition.getOrDefault("type", "device_state");
        final String metric = (String) condition.getOrDefault("metric",
            condition.getOrDefault("attribute", "value"));
        final String op     = (String) condition.getOrDefault("op", "eq");
        final Object value  = condition.get("value");

        if (metric == null || value == null) return "";

        final String jsOp = switch (op) {
            case "eq"  -> "===";
            case "neq" -> "!==";
            case "gt"  -> ">";
            case "gte" -> ">=";
            case "lt"  -> "<";
            case "lte" -> "<=";
            default    -> "===";
        };

        final String jsVal = value instanceof String ? "\"" + value + "\"" : value.toString();
        return "msg." + metric + " " + jsOp + " " + jsVal;
    }

    private String buildWebhookUrl(Automation automation) {
        return backendUrl + "/api/internal/automation/trigger";
    }

    private String buildWebhookBody(Automation automation) {
        return """
            {
              "automationId": "%s",
              "homeId": "%s",
              "tbDeviceId": "${deviceId}",
              "triggerType": "%s",
              "telemetry": ${msg}
            }
            """.formatted(
            automation.getId(),
            automation.getHomeId(),
            automation.getTriggerType()
        );
    }

    private RestClient tbClient() {
        return restClient.mutate()
            .defaultHeader("X-Authorization", "Bearer " + tbAuth.getToken())
            .build();
    }
}
