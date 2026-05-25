package com.smarthome.automation.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(
    name = "scenes",
    indexes = {@Index(name = "idx_scenes_home_id", columnList = "home_id")}
)
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Scene {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "home_id", nullable = false)
    private UUID homeId;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(name = "icon_key", length = 60)
    private String iconKey;

    @Column(name = "is_favorite", nullable = false)
    @Builder.Default
    private boolean favorite = false;

    @Column(name = "created_by")
    private UUID createdBy;

    @OneToMany(
        mappedBy    = "scene",
        cascade     = CascadeType.ALL,
        orphanRemoval = true,
        fetch       = FetchType.LAZY
    )
    @Builder.Default
    @OrderBy("sortOrder ASC")
    private List<SceneAction> actions = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public void addAction(SceneAction action) {
        action.setScene(this);
        this.actions.add(action);
    }
}
