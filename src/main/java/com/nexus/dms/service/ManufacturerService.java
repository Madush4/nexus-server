package com.nexus.dms.service;

import com.nexus.dms.entity.Manufacturer;
import com.nexus.dms.repository.ManufacturerRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ManufacturerService {

    private final ManufacturerRepository repository;

    public ManufacturerService(ManufacturerRepository repository) {
        this.repository = repository;
    }

    public List<Manufacturer> listManufacturers() {
        return repository.findAll();
    }

    public Manufacturer getManufacturer(UUID manufacturerId) {
        return repository.findById(manufacturerId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "No manufacturer with id: " + manufacturerId));
    }

    public Manufacturer registerManufacturer(Manufacturer payload) {
        return repository.save(payload);
    }

    public Manufacturer updateManufacturer(UUID manufacturerId, Manufacturer payload) {
        Manufacturer current = getManufacturer(manufacturerId);
        current.setName(payload.getName());
        current.setEmail(payload.getEmail());
        return repository.save(current);
    }

    public void removeManufacturer(UUID manufacturerId) {
        repository.delete(getManufacturer(manufacturerId));
    }
}

