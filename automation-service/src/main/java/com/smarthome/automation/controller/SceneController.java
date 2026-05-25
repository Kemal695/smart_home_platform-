package com.smarthome.automation.controller;

import com.smarthome.auth.AuthenticatedUser;
import com.smarthome.automation.dto.SceneRequest;
import com.smarthome.automation.dto.SceneResponse;
import com.smarthome.automation.service.SceneService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/scenes")
@RequiredArgsConstructor
public class SceneController {

    private final SceneService sceneService;

    @GetMapping
    public List<SceneResponse> list(@AuthenticationPrincipal AuthenticatedUser user) {
        return sceneService.getScenes(user.homeId());
    }

    @GetMapping("/{id}")
    public SceneResponse get(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser user) {
        return sceneService.getScene(id, user.homeId());
    }

    @PostMapping
    public ResponseEntity<SceneResponse> create(@Valid @RequestBody SceneRequest req,
                                                 @AuthenticationPrincipal AuthenticatedUser user) {
        var created = sceneService.createScene(req, user.homeId(), user.id());
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public SceneResponse update(@PathVariable UUID id, @Valid @RequestBody SceneRequest req,
                                 @AuthenticationPrincipal AuthenticatedUser user) {
        return sceneService.updateScene(id, req, user.homeId(), user.id());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser user) {
        sceneService.deleteScene(id, user.homeId(), user.id());
    }

    @PatchMapping("/{id}/favorite")
    public SceneResponse toggleFavorite(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser user) {
        sceneService.toggleFavorite(id, user.homeId(), user.id());
        return sceneService.getScene(id, user.homeId());
    }

    @PostMapping("/{id}/activate")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void activate(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser user) {
        sceneService.activate(user.homeId(), id);
    }
}
