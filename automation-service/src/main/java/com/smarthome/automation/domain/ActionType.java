package com.smarthome.automation.domain;

public enum ActionType {
    DEVICE_COMMAND, SCENE_ACTIVATE, NOTIFICATION, WEBHOOK;

    public static ActionType fromString(String value) {
        for (var a : values()) {
            if (a.name().equalsIgnoreCase(value)) return a;
        }
        throw new IllegalArgumentException("Unknown action type: " + value);
    }
}
