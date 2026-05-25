package com.smarthome.automation.repository;

import com.smarthome.automation.domain.Scene;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SceneRepository extends JpaRepository<Scene, UUID> {

    List<Scene> findByHomeIdOrderByCreatedAtDesc(UUID homeId);

    List<Scene> findByHomeId(UUID homeId);

    List<Scene> findByHomeIdAndFavoriteTrue(UUID homeId);

    Optional<Scene> findByIdAndHomeId(UUID id, UUID homeId);

    boolean existsByHomeIdAndId(UUID homeId, UUID id);
}
