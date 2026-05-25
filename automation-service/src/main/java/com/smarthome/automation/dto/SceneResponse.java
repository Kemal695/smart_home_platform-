package com.smarthome.automation.dto;

import com.smarthome.automation.domain.Scene;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record SceneResponse(
    UUID   id,
    UUID   homeId,
    String name,
    String iconKey,
    boolean favorite,
    List<ActionDto> actions,
    Instant createdAt
) {
    public static SceneResponse from(Scene s) {
        return new SceneResponse(
            s.getId(), s.getHomeId(), s.getName(), s.getIconKey(), s.isFavorite(),
            s.getActions().stream().map(a -> new ActionDto(
                a.getDeviceId(), a.getCommandJson(), a.getDelayMs(), a.getSortOrder()
            )).toList(),
            s.getCreatedAt()
        );
    }

    public record ActionDto(
        UUID deviceId,
        Map<String, Object> commandJson,
        int delayMs,
        int sortOrder
    ) {}
}
