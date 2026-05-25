package com.smarthome.automation.dto;

import com.smarthome.automation.domain.ActionType;
import com.smarthome.automation.domain.TriggerType;
import jakarta.validation.constraints.Size;

public record UpdateAutomationRequest(
    @Size(max = 120) String name,
    String description,
    Boolean enabled,
    TriggerType triggerType,
    ActionType actionType,
    String triggerConfig,
    String actionConfig
) {}
