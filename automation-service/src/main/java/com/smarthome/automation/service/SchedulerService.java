package com.smarthome.automation.service;

import com.smarthome.automation.domain.TriggerType;
import com.smarthome.automation.repository.AutomationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.scheduling.support.CronExpression;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class SchedulerService {

    private final AutomationRepository automationRepo;
    private final AutomationService    automationService;

    @Scheduled(fixedRate = 60_000)
    @Transactional(readOnly = true)
    public void evaluateScheduledAutomations() {
        var scheduled = automationRepo.findByTriggerTypeAndEnabled(TriggerType.SCHEDULE, true);

        if (scheduled.isEmpty()) return;

        var now = ZonedDateTime.now();

        scheduled.forEach(automation -> {
            try {
                automation.getRules().forEach(rule -> {
                    var cron     = (String) rule.getConditionJson().get("cron");
                    var timezone = (String) rule.getConditionJson()
                        .getOrDefault("timezone", "UTC");

                    if (cron == null) return;

                    var zoneId = safeZoneId(timezone);
                    var zonedNow = now.withZoneSameInstant(zoneId);

                    if (shouldFireNow(cron, zonedNow)) {
                        log.info("Schedule firing automation '{}' (cron={})",
                            automation.getName(), cron);
                        automationService.triggerManually(
                            automation.getHomeId(), automation.getId()
                        );
                    }
                });
            } catch (Exception e) {
                log.error("Schedule evaluation failed for automation {}: {}",
                    automation.getId(), e.getMessage());
            }
        });
    }

    private boolean shouldFireNow(String cronExpr, ZonedDateTime now) {
        try {
            var expr = CronExpression.parse(cronExpr);
            var prev = expr.next(now.minusMinutes(1).toLocalDateTime());
            if (prev == null) return false;

            var prevZoned = prev.atZone(now.getZone());
            return !prevZoned.isBefore(now.minusSeconds(60)) && !prevZoned.isAfter(now);
        } catch (Exception e) {
            log.warn("Invalid cron expression '{}': {}", cronExpr, e.getMessage());
            return false;
        }
    }

    private ZoneId safeZoneId(String timezone) {
        try { return ZoneId.of(timezone); }
        catch (Exception e) { return ZoneId.of("UTC"); }
    }
}
