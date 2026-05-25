package com.smarthome.automation.dto;

import com.smarthome.automation.domain.ActionType;
import com.smarthome.automation.domain.Automation;
import com.smarthome.automation.domain.TriggerType;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record AutomationResponse(
    UUID         id,
    UUID         homeId,
    String       name,
    String       description,
    boolean      enabled,
    TriggerType  triggerType,
    ActionType   actionType,
    Instant      lastRunAt,
    int          runCount,
    boolean      syncedToThingsBoard,
    List<RuleDto> rules,
    Instant      createdAt
) {
    public static AutomationResponse from(Automation a) {
        return new AutomationResponse(
            a.getId(), a.getHomeId(), a.getName(), a.getDescription(),
            a.isEnabled(), a.getTriggerType(), a.getActionType(),
            a.getLastRunAt(), a.getRunCount(),
            a.getTbRuleChainId() != null,
            a.getRules().stream().map(r -> new RuleDto(
                r.getId(), r.getConditionJson(), r.getActionJson(), r.getSortOrder()
            )).toList(),
            a.getCreatedAt()
        );
    }

    public record RuleDto(
        UUID id,
        Map<String, Object> conditionJson,
        Map<String, Object> actionJson,
        int sortOrder
    ) {}
}
