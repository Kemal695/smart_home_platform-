package com.smarthome.automation.domain.condition;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
public class ConditionEvaluator {

    public boolean evaluate(Map<String, Object> condition, Map<String, Object> event) {
        if (condition == null || condition.isEmpty()) return true;

        final String type = (String) condition.getOrDefault("type", "device_state");

        return switch (type) {
            case "device_state"     -> evaluateDeviceState(condition, event);
            case "sensor_threshold" -> evaluateSensorThreshold(condition, event);
            case "schedule"         -> true;
            case "manual"           -> false;
            default -> {
                log.warn("Unknown condition type: {}", type);
                yield false;
            }
        };
    }

    private boolean evaluateDeviceState(Map<String, Object> cond, Map<String, Object> event) {
        final String attribute = (String) cond.get("attribute");
        final String op        = (String) cond.getOrDefault("op", "eq");
        final Object expected  = cond.get("value");
        final Object actual    = event.get(attribute);

        if (actual == null || expected == null) return false;
        return applyOperator(actual, op, expected);
    }

    private boolean evaluateSensorThreshold(Map<String, Object> cond, Map<String, Object> event) {
        final String metric   = (String) cond.get("metric");
        final String op       = (String) cond.getOrDefault("op", "gt");
        final Object expected = cond.get("value");
        final Object actual   = event.get(metric);

        if (actual == null || expected == null) return false;
        return applyOperator(actual, op, expected);
    }

    private boolean applyOperator(Object actual, String op, Object expected) {
        return switch (op) {
            case "eq"  -> actual.toString().equalsIgnoreCase(expected.toString());
            case "neq" -> !actual.toString().equalsIgnoreCase(expected.toString());
            case "gt"  -> toDouble(actual) > toDouble(expected);
            case "gte" -> toDouble(actual) >= toDouble(expected);
            case "lt"  -> toDouble(actual) < toDouble(expected);
            case "lte" -> toDouble(actual) <= toDouble(expected);
            case "contains" -> actual.toString().contains(expected.toString());
            default -> {
                log.warn("Unknown operator: {}", op);
                yield false;
            }
        };
    }

    private double toDouble(Object val) {
        if (val instanceof Number n) return n.doubleValue();
        try { return Double.parseDouble(val.toString()); }
        catch (NumberFormatException e) { return 0; }
    }
}
