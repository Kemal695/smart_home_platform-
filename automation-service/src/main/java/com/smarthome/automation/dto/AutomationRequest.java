package com.smarthome.automation.dto;

import com.smarthome.automation.domain.ActionType;
import com.smarthome.automation.domain.TriggerType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.Map;

public record AutomationRequest(
    @NotBlank @Size(max = 120) String name,
    String description,
    @NotNull TriggerType triggerType,
    @NotNull ActionType actionType,
    @NotEmpty @Valid List<RuleRequest> rules
) {
    public record RuleRequest(
        @NotNull Map<String, Object> conditionJson,
        @NotNull Map<String, Object> actionJson
    ) {}
}
