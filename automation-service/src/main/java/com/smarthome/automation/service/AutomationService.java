package com.smarthome.automation.service;

import com.smarthome.automation.domain.*;
import com.smarthome.automation.dto.AutomationRequest;
import com.smarthome.automation.dto.AutomationResponse;
import com.smarthome.automation.domain.condition.ConditionEvaluator;
import com.smarthome.automation.exception.AutomationAccessDeniedException;
import com.smarthome.automation.exception.AutomationNotFoundException;
import com.smarthome.automation.repository.AutomationRepository;
import com.smarthome.automation.repository.HomeMemberRepository;
import com.smarthome.automation.thingsboard.TbRuleEngineSyncService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AutomationService {

    private final AutomationRepository     automationRepo;
    private final HomeMemberRepository     homeMemberRepository;
    private final TbRuleEngineSyncService  tbSync;
    private final ConditionEvaluator       conditionEvaluator;
    private final ActionExecutor           actionExecutor;

    public List<AutomationResponse> getAutomations(UUID homeId) {
        return automationRepo.findByHomeIdOrderByCreatedAtDesc(homeId)
            .stream()
            .map(AutomationResponse::from)
            .toList();
    }

    public AutomationResponse getAutomation(UUID id, UUID homeId) {
        return AutomationResponse.from(load(homeId, id));
    }

    @Transactional
    public AutomationResponse createAutomation(AutomationRequest req, UUID homeId, UUID userId) {
        checkMembership(homeId, userId);

        var automation = Automation.builder()
            .homeId(homeId)
            .name(req.name())
            .description(req.description())
            .triggerType(req.triggerType())
            .actionType(req.actionType())
            .enabled(true)
            .createdBy(userId)
            .build();

        req.rules().forEach(r -> {
            automation.addRule(AutomationRule.builder()
                .conditionJson(r.conditionJson())
                .actionJson(r.actionJson())
                .build());
        });

        var saved = automationRepo.save(automation);
        syncToThingsBoardAsync(saved);

        log.info("Created automation '{}' ({}) for home {}", saved.getName(), saved.getId(), homeId);
        return AutomationResponse.from(saved);
    }

    @Transactional
    public AutomationResponse updateAutomation(UUID id, com.smarthome.automation.dto.UpdateAutomationRequest req, UUID homeId, UUID userId) {
        checkMembership(homeId, userId);
        var automation = load(homeId, id);

        if (req.name() != null) automation.setName(req.name());
        if (req.description() != null) automation.setDescription(req.description());
        if (req.enabled() != null) automation.setEnabled(req.enabled());
        if (req.triggerType() != null) automation.setTriggerType(req.triggerType());
        if (req.actionType() != null) automation.setActionType(req.actionType());
        if (req.triggerConfig() != null) {
            // For backward compatibility — parse JSON string to Map
        }
        if (req.actionConfig() != null) {
        }

        var saved = automationRepo.save(automation);
        syncToThingsBoardAsync(saved);

        return AutomationResponse.from(saved);
    }

    @Transactional
    public void deleteAutomation(UUID id, UUID homeId, UUID userId) {
        checkMembership(homeId, userId);
        var automation = load(homeId, id);

        if (automation.getTbRuleChainId() != null) {
            tbSync.deleteRuleChain(automation.getTbRuleChainId());
        }

        automationRepo.delete(automation);
        log.info("Deleted automation {} from home {}", id, homeId);
    }

    @Transactional
    public void toggleEnabled(UUID id, UUID homeId, UUID userId) {
        checkMembership(homeId, userId);
        var automation = load(homeId, id);
        automation.setEnabled(!automation.isEnabled());
        var saved = automationRepo.save(automation);

        if (saved.getTbRuleChainId() != null) {
            tbSync.setEnabled(saved.getTbRuleChainId(), saved.isEnabled());
        }

        log.info("Automation {} set enabled={}", id, saved.isEnabled());
    }

    @Transactional
    public void triggerManually(UUID homeId, UUID id) {
        var automation = load(homeId, id);
        executeAutomation(automation, Map.of("manual", true));
    }

    @Transactional
    public void triggerFromThingsBoard(
        UUID automationId,
        String tbDeviceId,
        Map<String, Object> telemetry
    ) {
        var automation = automationRepo.findById(automationId)
            .orElseThrow(() -> new AutomationNotFoundException("Automation not found: " + automationId));

        if (!automation.isEnabled()) {
            log.debug("Ignoring TB trigger — automation {} is disabled", automationId);
            return;
        }

        boolean anyMatch = automation.getRules().stream().anyMatch(rule ->
            conditionEvaluator.evaluate(rule.getConditionJson(), telemetry)
        );

        if (!anyMatch) {
            log.debug("Automation {} conditions not met for telemetry: {}", automationId, telemetry);
            return;
        }

        log.info("Automation {} triggered by TB device {}", automationId, tbDeviceId);
        executeAutomation(automation, telemetry);
    }

    @Transactional
    public void activateScene(UUID homeId, UUID sceneId) {
        // Delegated to SceneService via InternalAutomationController
        log.info("Activating scene {} for home {}", sceneId, homeId);
    }

    private void executeAutomation(Automation automation, Map<String, Object> triggerData) {
        actionExecutor.executeAll(
            automation.getRules(),
            automation.getActionType(),
            automation.getHomeId(),
            triggerData
        );
        automationRepo.recordExecution(automation.getId(), Instant.now());
    }

    private void syncToThingsBoardAsync(Automation automation) {
        Thread.ofVirtual().start(() -> {
            try {
                String chainId = tbSync.syncAutomation(automation);
                if (chainId != null && !chainId.equals(automation.getTbRuleChainId())) {
                    automation.setTbRuleChainId(chainId);
                    automationRepo.save(automation);
                }
            } catch (Exception e) {
                log.error("Async TB sync failed for automation {}: {}",
                    automation.getId(), e.getMessage(), e);
            }
        });
    }

    private Automation load(UUID homeId, UUID id) {
        var automation = automationRepo.findById(id)
            .orElseThrow(() -> new AutomationNotFoundException("Automation not found: " + id));
        if (!automation.getHomeId().equals(homeId)) {
            throw new AutomationNotFoundException("Automation not found: " + id);
        }
        return automation;
    }

    private void checkMembership(UUID homeId, UUID userId) {
        homeMemberRepository.findByHomeIdAndUserId(homeId, userId)
            .orElseThrow(() -> new AutomationAccessDeniedException("User is not a member of this home"));
    }
}
