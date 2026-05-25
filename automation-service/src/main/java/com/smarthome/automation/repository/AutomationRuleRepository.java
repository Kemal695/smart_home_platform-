package com.smarthome.automation.repository;

import com.smarthome.automation.domain.AutomationRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AutomationRuleRepository extends JpaRepository<AutomationRule, UUID> {
    List<AutomationRule> findByAutomationIdOrderBySortOrder(UUID automationId);
    void deleteByAutomationId(UUID automationId);
}
