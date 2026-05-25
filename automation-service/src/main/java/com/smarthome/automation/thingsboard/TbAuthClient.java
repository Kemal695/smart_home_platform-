package com.smarthome.automation.thingsboard;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j
@Component
@RequiredArgsConstructor
public class TbAuthClient {

    private final RestClient restClient;

    @Value("${thingsboard.base-url}")
    private String tbBaseUrl;

    @Value("${thingsboard.username}")
    private String username;

    @Value("${thingsboard.password}")
    private String password;

    @Value("${thingsboard.token-ttl-seconds:3300}")
    private int tokenTtlSeconds;

    private volatile String  cachedToken;
    private volatile Instant tokenExpiresAt = Instant.MIN;
    private final    ReentrantLock lock = new ReentrantLock();

    public String getToken() {
        if (Instant.now().isBefore(tokenExpiresAt)) return cachedToken;
        lock.lock();
        try {
            if (Instant.now().isBefore(tokenExpiresAt)) return cachedToken;
            return refresh();
        } finally {
            lock.unlock();
        }
    }

    @SuppressWarnings("unchecked")
    private String refresh() {
        log.info("[Automation] Refreshing ThingsBoard JWT");

        var response = restClient.post()
            .uri(tbBaseUrl + "/api/auth/login")
            .body(Map.of("username", username, "password", password))
            .retrieve()
            .body(Map.class);

        if (response == null || !response.containsKey("token")) {
            throw new IllegalStateException("ThingsBoard login returned no token");
        }

        cachedToken    = (String) response.get("token");
        tokenExpiresAt = Instant.now().plusSeconds(tokenTtlSeconds);
        return cachedToken;
    }
}
