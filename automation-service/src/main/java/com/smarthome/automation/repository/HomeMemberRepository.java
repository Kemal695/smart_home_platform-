package com.smarthome.automation.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface HomeMemberRepository extends JpaRepository<HomeMember, UUID> {
    Optional<HomeMember> findByHomeIdAndUserId(UUID homeId, UUID userId);
}
