package com.smarthome.automation.controller;

import com.smarthome.auth.AuthenticatedUser;
import com.smarthome.automation.dto.AutomationRequest;
import com.smarthome.automation.dto.AutomationResponse;
import com.smarthome.automation.dto.ToggleRequest;
import com.smarthome.automation.dto.UpdateAutomationRequest;
import com.smarthome.automation.service.AutomationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/automations")
@RequiredArgsConstructor
public class AutomationController {

    private final AutomationService automationService;

    @GetMapping
    public List<AutomationResponse> list(@AuthenticationPrincipal AuthenticatedUser user) {
        return automationService.getAutomations(user.homeId());
    }

    @GetMapping("/{id}")
    public AutomationResponse get(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser user) {
        return automationService.getAutomation(id, user.homeId());
    }

    @PostMapping
    public ResponseEntity<AutomationResponse> create(@Valid @RequestBody AutomationRequest req,
                                                      @AuthenticationPrincipal AuthenticatedUser user) {
        var created = automationService.createAutomation(req, user.homeId(), user.id());
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public AutomationResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateAutomationRequest req,
                                      @AuthenticationPrincipal AuthenticatedUser user) {
        return automationService.updateAutomation(id, req, user.homeId(), user.id());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser user) {
        automationService.deleteAutomation(id, user.homeId(), user.id());
    }

    @PatchMapping("/{id}/toggle")
    public AutomationResponse toggle(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser user) {
        automationService.toggleEnabled(id, user.homeId(), user.id());
        return automationService.getAutomation(id, user.homeId());
    }

    @PostMapping("/{id}/trigger")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void trigger(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser user) {
        automationService.triggerManually(user.homeId(), id);
    }
}
