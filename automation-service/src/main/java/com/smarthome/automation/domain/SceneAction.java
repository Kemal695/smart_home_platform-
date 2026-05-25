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
    name = "scene_actions",
    indexes = {
        @Index(name = "idx_scene_actions_scene_id",  columnList = "scene_id"),
        @Index(name = "idx_scene_actions_device_id", columnList = "device_id"),
    }
)
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class SceneAction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "scene_id", nullable = false)
    private Scene scene;

    @Column(name = "device_id", nullable = false)
    private UUID deviceId;

    @Type(JsonType.class)
    @Column(name = "command_json", columnDefinition = "jsonb", nullable = false)
    private Map<String, Object> commandJson;

    @Column(name = "delay_ms", nullable = false)
    @Builder.Default
    private int delayMs = 0;

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private int sortOrder = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();
}
