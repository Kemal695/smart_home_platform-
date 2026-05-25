package com.smarthome.automation.repository;

import com.smarthome.automation.domain.Automation;
import com.smarthome.automation.domain.TriggerType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AutomationRepository extends JpaRepository<Automation, UUID> {

    List<Automation> findByHomeId(UUID homeId);

    List<Automation> findByHomeIdOrderByCreatedAtDesc(UUID homeId);

    Optional<Automation> findByIdAndHomeId(UUID id, UUID homeId);

    List<Automation> findByHomeIdAndEnabled(UUID homeId, boolean enabled);

    List<Automation> findByTriggerTypeAndEnabled(TriggerType type, boolean enabled);

    @Query(value = """
        SELECT a.* FROM automations a
        JOIN automation_rules r ON r.automation_id = a.id
        WHERE a.home_id = :homeId
          AND a.is_enabled = true
          AND r.condition_json ->> 'deviceId' = :deviceId
        """, nativeQuery = true)
    List<Automation> findEnabledByWatchedDevice(
        @Param("homeId")   UUID homeId,
        @Param("deviceId") String deviceId
    );

    @Modifying
    @Query("UPDATE Automation a SET a.lastRunAt = :now, a.runCount = a.runCount + 1 WHERE a.id = :id")
    void recordExecution(@Param("id") UUID id, @Param("now") Instant now);

    boolean existsByHomeIdAndId(UUID homeId, UUID id);

    long countByHomeId(UUID homeId);
}
