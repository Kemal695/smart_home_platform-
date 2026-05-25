package com.smarthome.automation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record SceneRequest(
    @NotBlank @Size(max = 120) String name,
    String iconKey,
    boolean favorite,
    @NotEmpty List<SceneActionRequest> actions
) {
    public record SceneActionRequest(
        @NotNull UUID   deviceId,
        @NotNull Map<String, Object> commandJson,
        int delayMs,
        int sortOrder
    ) {}
}
