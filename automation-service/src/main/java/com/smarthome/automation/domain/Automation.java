package com.smarthome.automation.domain;

import io.hypersistence.utils.hibernate.type.json.JsonType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.Type;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(
    name = "automations",
    indexes = {
        @Index(name = "idx_automations_home_id",    columnList = "home_id"),
        @Index(name = "idx_automations_is_enabled", columnList = "is_enabled"),
    }
)
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Automation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "home_id", nullable = false)
    private UUID homeId;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_enabled", nullable = false)
    @Builder.Default
    private boolean enabled = true;

    @Enumerated(EnumType.STRING)
    @Column(name = "trigger_type", nullable = false, length = 30)
    private TriggerType triggerType;

    @Enumerated(EnumType.STRING)
    @Column(name = "action_type", nullable = false, length = 30)
    private ActionType actionType;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "last_run_at")
    private Instant lastRunAt;

    @Column(name = "run_count", nullable = false)
    @Builder.Default
    private int runCount = 0;

    @Column(name = "tb_rule_chain_id", length = 36)
    private String tbRuleChainId;

    @Column(name = "tb_rule_node_id", length = 36)
    private String tbRuleNodeId;

    @OneToMany(
        mappedBy = "automation",
        cascade  = CascadeType.ALL,
        orphanRemoval = true,
        fetch    = FetchType.LAZY
    )
    @Builder.Default
    @OrderBy("sortOrder ASC")
    private List<AutomationRule> rules = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public void recordExecution() {
        this.lastRunAt = Instant.now();
        this.runCount++;
    }

    public void addRule(AutomationRule rule) {
        rule.setAutomation(this);
        this.rules.add(rule);
    }
}
