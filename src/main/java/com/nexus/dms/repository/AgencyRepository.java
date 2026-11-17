package com.nexus.dms.repository;

import com.nexus.dms.entity.Agency;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AgencyRepository extends JpaRepository<Agency, UUID> {
    Optional<Agency> findByAgencyCode(String agencyCode);
}
