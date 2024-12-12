package org.example.web;

import org.springframework.web.bind.annotation.*;

@RestController
public class StatusAPI {
    @GetMapping("/status")
    public String hello() {
        return "API connected successfully !";
    }
}
