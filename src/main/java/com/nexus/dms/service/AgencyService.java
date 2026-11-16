package com.nexus.dms.service;

import com.nexus.dms.entity.Agency;
import com.nexus.dms.repository.AgencyRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AgencyService {

    private final AgencyRepository repository;

    public AgencyService(AgencyRepository repository) {
        this.repository = repository;
    }

    public List<Agency> listAgencies() {
        return repository.findAll();
    }

    public Agency getAgency(UUID agencyId) {
        return repository.findById(agencyId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "No agency with id: " + agencyId));
    }

    public Agency registerAgency(Agency payload) {
        return repository.save(payload);
    }

    public Agency updateAgency(UUID agencyId, Agency payload) {
        Agency current = getAgency(agencyId);
        current.setName(payload.getName());
        current.setAddress(payload.getAddress());
        return repository.save(current);
    }

    public void removeAgency(UUID agencyId) {
        repository.delete(getAgency(agencyId));
    }
}

