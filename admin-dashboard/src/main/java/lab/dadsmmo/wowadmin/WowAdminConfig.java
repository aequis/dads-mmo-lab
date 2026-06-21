package lab.dadsmmo.wowadmin;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(WowAdminProperties.class)
public class WowAdminConfig {
}
