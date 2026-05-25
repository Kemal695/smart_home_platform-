package com.smarthome.automation.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

@Configuration
@EnableAsync
public class SchedulingConfig {

    @Bean(name = "automationExecutor")
    public Executor automationExecutor() {
        return command -> Thread.ofVirtual()
            .name("automation-", 0)
            .start(command);
    }

    @Bean(name = "schedulerExecutor")
    public Executor schedulerExecutor() {
        var exec = new ThreadPoolTaskExecutor();
        exec.setCorePoolSize(2);
        exec.setMaxPoolSize(4);
        exec.setThreadNamePrefix("scheduler-");
        exec.initialize();
        return exec;
    }
}
