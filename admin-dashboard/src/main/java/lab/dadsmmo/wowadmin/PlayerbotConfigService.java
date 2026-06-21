package lab.dadsmmo.wowadmin;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.stereotype.Service;

@Service
public class PlayerbotConfigService {
    private static final Pattern OPTION = Pattern.compile("^([A-Za-z0-9_.]+)\\s*=\\s*(.*)$");
    private static final Pattern SECTION = Pattern.compile("^# ([A-Z][A-Z0-9 /_-]{2,}?)(?:\\s+#)?\\s*$");
    private static final List<String> DEFAULT_PATHS = List.of(
            "/playerbots.conf.dist",
            "/azerothcore/modules/mod-playerbots/conf/playerbots.conf.dist",
            "/azerothcore/env/dist/etc/modules/playerbots.conf.dist");

    private final WowAdminProperties properties;

    public PlayerbotConfigService(WowAdminProperties properties) {
        this.properties = properties;
    }

    public PlayerbotConfigView load() {
        List<String> searchedPaths = configPaths();
        for (String candidate : searchedPaths) {
            Path path = Path.of(candidate);
            if (Files.isRegularFile(path) && Files.isReadable(path)) {
                try {
                    return parse(path, Files.readAllLines(path, StandardCharsets.UTF_8), searchedPaths);
                } catch (IOException ex) {
                    return new PlayerbotConfigView(candidate, searchedPaths, List.of(), List.of(), 0, ex.getMessage());
                }
            }
        }
        return new PlayerbotConfigView(null, searchedPaths, List.of(), List.of(), 0,
                "No readable Playerbots config template found.");
    }

    private PlayerbotConfigView parse(Path path, List<String> lines, List<String> searchedPaths) {
        String section = "General";
        List<String> comments = new ArrayList<>();
        List<PlayerbotConfigOption> options = new ArrayList<>();

        for (String line : lines) {
            String trimmed = line.strip();
            Matcher option = OPTION.matcher(trimmed);
            if (option.matches()) {
                String key = option.group(1);
                String defaultValue = option.group(2).strip();
                List<String> envNames = envNames(key);
                EnvValue envValue = envValue(envNames);
                options.add(new PlayerbotConfigOption(
                        section,
                        key,
                        defaultValue,
                        envValue.value() == null ? defaultValue : envValue.value(),
                        envValue.name(),
                        envNames,
                        String.join(" ", comments).replaceAll("\\s+", " ").strip()));
                comments.clear();
                continue;
            }

            if (trimmed.startsWith("#")) {
                Matcher sectionMatcher = SECTION.matcher(trimmed);
                if (sectionMatcher.matches()) {
                    String heading = sectionMatcher.group(1);
                    if (!"SECTION INDEX".equals(heading)) {
                        section = titleCase(heading);
                    }
                    comments.clear();
                } else {
                    String comment = trimmed.substring(1).strip();
                    if (!comment.isBlank() && !comment.chars().allMatch(ch -> ch == '#')) {
                        comments.add(comment);
                    }
                }
            } else if (trimmed.isBlank()) {
                comments.clear();
            }
        }

        long overridden = options.stream().filter(PlayerbotConfigOption::overridden).count();
        return new PlayerbotConfigView(path.toString(), searchedPaths, options, sections(options), overridden, null);
    }

    private List<PlayerbotConfigSection> sections(List<PlayerbotConfigOption> options) {
        Map<String, List<PlayerbotConfigOption>> grouped = new LinkedHashMap<>();
        for (PlayerbotConfigOption option : options) {
            grouped.computeIfAbsent(option.section(), ignored -> new ArrayList<>()).add(option);
        }

        List<PlayerbotConfigSection> sections = new ArrayList<>();
        for (Map.Entry<String, List<PlayerbotConfigOption>> entry : grouped.entrySet()) {
            long overridden = entry.getValue().stream().filter(PlayerbotConfigOption::overridden).count();
            sections.add(new PlayerbotConfigSection(entry.getKey(), entry.getValue(), overridden));
        }
        return List.copyOf(sections);
    }

    private List<String> configPaths() {
        LinkedHashSet<String> paths = new LinkedHashSet<>();
        if (properties.playerbots() != null && properties.playerbots().configPaths() != null) {
            properties.playerbots().configPaths().stream()
                    .filter(path -> path != null && !path.isBlank())
                    .forEach(paths::add);
        }
        paths.addAll(DEFAULT_PATHS);
        return List.copyOf(paths);
    }

    private EnvValue envValue(List<String> names) {
        Map<String, String> env = System.getenv();
        for (String name : names) {
            String value = env.get(name);
            if (value != null) {
                return new EnvValue(name, value);
            }
        }
        return new EnvValue(null, null);
    }

    private List<String> envNames(String key) {
        Set<String> names = new LinkedHashSet<>();
        String snake = toSnake(key);
        names.add("AC_" + snake);
        names.add(snake);
        names.add("AC_" + key.toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9]+", "_"));
        return List.copyOf(names);
    }

    private String toSnake(String key) {
        StringBuilder result = new StringBuilder();
        char previous = 0;
        for (int index = 0; index < key.length(); index++) {
            char current = key.charAt(index);
            char next = index + 1 < key.length() ? key.charAt(index + 1) : 0;
            if (!Character.isLetterOrDigit(current)) {
                appendUnderscore(result);
            } else {
                if (Character.isUpperCase(current) && index > 0
                        && (Character.isLowerCase(previous) || Character.isDigit(previous)
                        || (Character.isUpperCase(previous) && Character.isLowerCase(next)))) {
                    appendUnderscore(result);
                }
                result.append(Character.toUpperCase(current));
            }
            previous = current;
        }
        return result.toString().replaceAll("_+", "_").replaceAll("^_|_$", "");
    }

    private void appendUnderscore(StringBuilder result) {
        if (!result.isEmpty() && result.charAt(result.length() - 1) != '_') {
            result.append('_');
        }
    }

    private String titleCase(String value) {
        String[] words = value.toLowerCase(Locale.ROOT).split("[ _/-]+");
        List<String> titled = new ArrayList<>();
        for (String word : words) {
            if (!word.isBlank()) {
                titled.add(Character.toUpperCase(word.charAt(0)) + word.substring(1));
            }
        }
        return String.join(" ", titled);
    }

    public record PlayerbotConfigView(
            String sourcePath,
            List<String> searchedPaths,
            List<PlayerbotConfigOption> options,
            List<PlayerbotConfigSection> sections,
            long overriddenCount,
            String error) {
    }

    public record PlayerbotConfigSection(
            String name,
            List<PlayerbotConfigOption> options,
            long overriddenCount) {
        public boolean hasOverrides() {
            return overriddenCount > 0;
        }

        public List<PlayerbotConfigOption> overriddenOptions() {
            return options.stream().filter(PlayerbotConfigOption::overridden).toList();
        }
    }

    public record PlayerbotConfigOption(
            String section,
            String key,
            String defaultValue,
            String effectiveValue,
            String overrideEnv,
            List<String> envNames,
            String description) {
        public boolean overridden() {
            return overrideEnv != null;
        }

        public String primaryEnvName() {
            return envNames.isEmpty() ? "" : envNames.get(0);
        }
    }

    private record EnvValue(String name, String value) {
    }
}
