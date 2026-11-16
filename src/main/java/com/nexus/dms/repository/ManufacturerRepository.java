package com.nexus.dms.repository;

import com.nexus.dms.entity.Manufacturer;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ManufacturerRepository extends JpaRepository<Manufacturer, UUID> {
    Optional<Manufacturer> findByEmail(String email);
}

