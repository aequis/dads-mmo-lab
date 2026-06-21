package lab.dadsmmo.wowadmin;

import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "wow")
public record WowAdminProperties(Databases databases, Soap soap, Playerbots playerbots) {
    public record Databases(String auth, String characters, String playerbots) {
    }

    public record Playerbots(List<String> configPaths) {
    }

    public record Soap(String url, String username, String password) {
        public boolean enabled() {
            return hasText(url) && hasText(username) && hasText(password);
        }

        private static boolean hasText(String value) {
            return value != null && !value.isBlank();
        }
    }
}
