package lab.dadsmmo.wowadmin;

import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "wow")
public record WowAdminProperties(Databases databases, Soap soap, Playerbots playerbots, Docker docker) {
    public record Databases(String auth, String characters, String playerbots) {
    }

    public record Playerbots(List<String> configPaths, String overrideEnvPath, String generatedConfigPath) {
    }

    public record Docker(String socketPath, String worldserverContainer) {
        public boolean enabled() {
            return hasText(socketPath) && hasText(worldserverContainer);
        }
    }

    public record Soap(String url, String username, String password) {
        public boolean enabled() {
            return hasText(url) && hasText(username) && hasText(password);
        }

        private static boolean hasText(String value) {
            return value != null && !value.isBlank();
        }
    }

    private static boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
