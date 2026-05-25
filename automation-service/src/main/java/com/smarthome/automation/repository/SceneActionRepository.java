package com.smarthome.automation.repository;

import com.smarthome.automation.domain.SceneAction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SceneActionRepository extends JpaRepository<SceneAction, UUID> {
    List<SceneAction> findBySceneIdOrderBySortOrder(UUID sceneId);
    void deleteBySceneId(UUID sceneId);
}
