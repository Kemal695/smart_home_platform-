package com.smarthome.automation.repository;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "home_members")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class HomeMember {
    @Id
    private UUID id;
    @Column(name = "home_id")
    private UUID homeId;
    @Column(name = "user_id")
    private UUID userId;
    @Column(length = 20)
    private String permission;
}
