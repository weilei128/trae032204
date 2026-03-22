package com.shop.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "data.csv")
public class DataConfig {
    private String path;
    private String usersFile;
    private String productsFile;
    private String ordersFile;
}
