package com.nexus.dms.service;

import com.nexus.dms.entity.Agency;
import com.nexus.dms.entity.DeliveryAgent;
import com.nexus.dms.repository.AgencyRepository;
import com.nexus.dms.repository.DeliveryAgentRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class DeliveryAgentService {

    private final DeliveryAgentRepository agentRepo;
    private final AgencyRepository agencyRepo;

    public DeliveryAgentService(DeliveryAgentRepository agentRepo, AgencyRepository agencyRepo) {
        this.agentRepo = agentRepo;
        this.agencyRepo = agencyRepo;
    }

    public List<DeliveryAgent> listDeliveryAgents() {
        return agentRepo.findAll();
    }

    public DeliveryAgent getDeliveryAgent(UUID agentId) {
        return agentRepo.findById(agentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "No delivery agent with id: " + agentId));
    }

    public DeliveryAgent registerDeliveryAgent(DeliveryAgent payload, UUID agencyId) {
        if (agencyId != null) {
            Agency linkedAgency = agencyRepo.findById(agencyId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "No agency with id: " + agencyId));
            payload.setAgency(linkedAgency);
        }
        return agentRepo.save(payload);
    }

    public void removeDeliveryAgent(UUID agentId) {
        agentRepo.delete(getDeliveryAgent(agentId));
    }
}

