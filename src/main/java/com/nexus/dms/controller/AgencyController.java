package com.nexus.dms.controller;

import com.nexus.dms.entity.Agency;
import com.nexus.dms.service.AgencyService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/agencies")
public class AgencyController {

    private final AgencyService service;

    public AgencyController(AgencyService service) {
        this.service = service;
    }

    @GetMapping
    public List<Agency> getAll() {
        return service.listAgencies();
    }

    @GetMapping("/{id}")
    public Agency getOne(@PathVariable UUID id) {
        return service.getAgency(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Agency register(@Valid @RequestBody Agency payload) {
        return service.registerAgency(payload);
    }

    @PutMapping("/{id}")
    public Agency update(@PathVariable UUID id, @Valid @RequestBody Agency payload) {
        return service.updateAgency(id, payload);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@PathVariable UUID id) {
        service.removeAgency(id);
    }
}

