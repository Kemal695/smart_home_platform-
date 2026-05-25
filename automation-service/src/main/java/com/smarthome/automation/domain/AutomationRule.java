package com.smarthome.automation.domain;

import io.hypersistence.utils.hibernate.type.json.JsonType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Type;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(
    name = "automation_rules",
    indexes = {
        @Index(name = "idx_automation_rules_automation_id", columnList = "automation_id"),
    }
)
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class AutomationRule {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "automation_id", nullable = false)
    private Automation automation;

    @Type(JsonType.class)
    @Column(name = "condition_json", columnDefinition = "jsonb", nullable = false)
    private Map<String, Object> conditionJson;

    @Type(JsonType.class)
    @Column(name = "action_json", columnDefinition = "jsonb", nullable = false)
    private Map<String, Object> actionJson;

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private int sortOrder = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();
}
