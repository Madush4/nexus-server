package com.nexus.dms.controller;

import com.nexus.dms.entity.DeliveryAgent;
import com.nexus.dms.service.DeliveryAgentService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/delivery-agents")
public class DeliveryAgentController {

    private final DeliveryAgentService service;

    public DeliveryAgentController(DeliveryAgentService service) {
        this.service = service;
    }

    @GetMapping
    public List<DeliveryAgent> getAll() {
        return service.listDeliveryAgents();
    }

    @GetMapping("/{id}")
    public DeliveryAgent getOne(@PathVariable UUID id) {
        return service.getDeliveryAgent(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DeliveryAgent register(
            @Valid @RequestBody DeliveryAgent payload,
            @RequestParam(required = false) UUID agencyId) {
        return service.registerDeliveryAgent(payload, agencyId);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@PathVariable UUID id) {
        service.removeDeliveryAgent(id);
    }
}

