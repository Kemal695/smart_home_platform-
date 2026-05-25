package com.smarthome.automation.service;

import com.smarthome.automation.domain.ActionType;
import com.smarthome.automation.domain.Scene;
import com.smarthome.automation.domain.SceneAction;
import com.smarthome.automation.dto.SceneRequest;
import com.smarthome.automation.dto.SceneResponse;
import com.smarthome.automation.exception.AutomationAccessDeniedException;
import com.smarthome.automation.exception.SceneNotFoundException;
import com.smarthome.automation.repository.HomeMemberRepository;
import com.smarthome.automation.repository.SceneRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class SceneService {

    private final SceneRepository      sceneRepo;
    private final HomeMemberRepository homeMemberRepository;
    private final ActionExecutor       actionExecutor;

    public List<SceneResponse> getScenes(UUID homeId) {
        return sceneRepo.findByHomeId(homeId).stream().map(SceneResponse::from).toList();
    }

    public SceneResponse getScene(UUID id, UUID homeId) {
        return SceneResponse.from(load(homeId, id));
    }

    @Transactional
    public SceneResponse createScene(SceneRequest req, UUID homeId, UUID userId) {
        checkMembership(homeId, userId);

        var scene = Scene.builder()
            .homeId(homeId)
            .name(req.name())
            .iconKey(req.iconKey())
            .favorite(req.favorite())
            .createdBy(userId)
            .build();

        var sortOrder = new int[]{0};
        req.actions().forEach(a -> scene.addAction(
            SceneAction.builder()
                .deviceId(a.deviceId())
                .commandJson(a.commandJson())
                .delayMs(a.delayMs())
                .sortOrder(sortOrder[0]++)
                .build()
        ));

        var saved = sceneRepo.save(scene);
        log.info("Created scene '{}' ({}) for home {}", saved.getName(), saved.getId(), homeId);
        return SceneResponse.from(saved);
    }

    @Transactional
    public SceneResponse updateScene(UUID id, SceneRequest req, UUID homeId, UUID userId) {
        checkMembership(homeId, userId);
        var scene = load(homeId, id);

        scene.setName(req.name());
        scene.setIconKey(req.iconKey());
        scene.setFavorite(req.favorite());

        scene.getActions().clear();
        var sortOrder = new int[]{0};
        req.actions().forEach(a -> scene.addAction(
            SceneAction.builder()
                .deviceId(a.deviceId())
                .commandJson(a.commandJson())
                .delayMs(a.delayMs())
                .sortOrder(sortOrder[0]++)
                .build()
        ));

        var saved = sceneRepo.save(scene);
        return SceneResponse.from(saved);
    }

    @Transactional
    public void deleteScene(UUID id, UUID homeId, UUID userId) {
        checkMembership(homeId, userId);
        var scene = load(homeId, id);
        sceneRepo.delete(scene);
    }

    @Transactional
    public void toggleFavorite(UUID id, UUID homeId, UUID userId) {
        checkMembership(homeId, userId);
        var scene = load(homeId, id);
        scene.setFavorite(!scene.isFavorite());
        sceneRepo.save(scene);
    }

    public void activate(UUID homeId, UUID id) {
        var scene = load(homeId, id);
        log.info("Activating scene '{}' ({}) for home {}", scene.getName(), id, homeId);

        Thread.ofVirtual().start(() -> {
            for (SceneAction action : scene.getActions()) {
                try {
                    if (action.getDelayMs() > 0) {
                        Thread.sleep(action.getDelayMs());
                    }
                    actionExecutor.execute(
                        action.getCommandJson(),
                        ActionType.DEVICE_COMMAND,
                        homeId,
                        Map.of()
                    );
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                } catch (Exception e) {
                    log.error("Scene action failed for device {}: {}",
                        action.getDeviceId(), e.getMessage());
                }
            }
            log.info("Scene '{}' activation complete", scene.getName());
        });
    }

    private Scene load(UUID homeId, UUID id) {
        var scene = sceneRepo.findById(id)
            .orElseThrow(() -> new SceneNotFoundException("Scene not found: " + id));
        if (!scene.getHomeId().equals(homeId)) {
            throw new SceneNotFoundException("Scene not found: " + id);
        }
        return scene;
    }

    private void checkMembership(UUID homeId, UUID userId) {
        homeMemberRepository.findByHomeIdAndUserId(homeId, userId)
            .orElseThrow(() -> new AutomationAccessDeniedException("User is not a member of this home"));
    }
}
