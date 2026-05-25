package com.smarthome.automation.domain;

public enum TriggerType {
    SCHEDULE, DEVICE_STATE, SENSOR_THRESHOLD, SUNRISE_SUNSET, MANUAL;

    public static TriggerType fromString(String value) {
        for (var t : values()) {
            if (t.name().equalsIgnoreCase(value)) return t;
        }
        throw new IllegalArgumentException("Unknown trigger type: " + value);
    }
}
