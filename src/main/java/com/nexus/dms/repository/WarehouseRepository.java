package com.nexus.dms.repository;

import com.nexus.dms.entity.Warehouse;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface WarehouseRepository extends JpaRepository<Warehouse, UUID> {
    Optional<Warehouse> findByWarehouseCode(String warehouseCode);
}

