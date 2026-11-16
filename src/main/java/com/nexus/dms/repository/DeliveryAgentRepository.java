package com.nexus.dms.repository;

import com.nexus.dms.entity.DeliveryAgent;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DeliveryAgentRepository extends JpaRepository<DeliveryAgent, UUID> {
    List<DeliveryAgent> findByAgency_AgencyId(UUID agencyId);
}

