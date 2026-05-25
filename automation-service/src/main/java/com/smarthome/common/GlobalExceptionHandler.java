package com.smarthome.common;

import com.smarthome.automation.exception.AutomationAccessDeniedException;
import com.smarthome.automation.exception.AutomationNotFoundException;
import com.smarthome.automation.exception.SceneNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler({AutomationNotFoundException.class, SceneNotFoundException.class})
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ApiError handleNotFound(RuntimeException ex, HttpServletRequest req) {
        return ApiError.of("NOT_FOUND", ex.getMessage(), traceId());
    }

    @ExceptionHandler(AutomationAccessDeniedException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public ApiError handleForbidden(AutomationAccessDeniedException ex, HttpServletRequest req) {
        return ApiError.of("ACCESS_DENIED", ex.getMessage(), traceId());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiError handleBadArgument(IllegalArgumentException ex) {
        return ApiError.of("BAD_REQUEST", ex.getMessage(), traceId());
    }

    @ExceptionHandler(IllegalStateException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public ApiError handleConflict(IllegalStateException ex) {
        return ApiError.of("CONFLICT", ex.getMessage(), traceId());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
    public Map<String, Object> handleValidation(MethodArgumentNotValidException ex) {
        var fields = ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(
                FieldError::getField,
                f -> f.getDefaultMessage() != null ? f.getDefaultMessage() : "invalid",
                (a, b) -> a
            ));
        return Map.of(
            "error",       "VALIDATION_FAILED",
            "message",     "Request validation failed",
            "fieldErrors", fields,
            "traceId",     traceId()
        );
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ApiError handleUnexpected(Exception ex, HttpServletRequest req) {
        log.error("Unhandled exception on {}: {}", req.getRequestURI(), ex.getMessage(), ex);
        return ApiError.of("INTERNAL_ERROR", "An unexpected error occurred", traceId());
    }

    private String traceId() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    public record ApiError(String error, String message, String traceId, String timestamp) {
        public static ApiError of(String code, String message, String traceId) {
            return new ApiError(code, message, traceId, java.time.Instant.now().toString());
        }
    }
}
