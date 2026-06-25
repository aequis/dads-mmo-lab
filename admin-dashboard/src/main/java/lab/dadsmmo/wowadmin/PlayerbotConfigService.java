package lab.dadsmmo.wowadmin;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
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
        Map<String, String> fileOverrides = readOverrideValues();
        for (String candidate : searchedPaths) {
            Path path = Path.of(candidate);
            if (Files.isRegularFile(path) && Files.isReadable(path)) {
                try {
                    return parse(path, Files.readAllLines(path, StandardCharsets.UTF_8), searchedPaths, fileOverrides);
                } catch (IOException ex) {
                    return new PlayerbotConfigView(candidate, searchedPaths, List.of(), List.of(), 0, ex.getMessage());
                }
            }
        }
        return new PlayerbotConfigView(null, searchedPaths, List.of(), List.of(), 0,
                "No readable Playerbots config template found.");
    }

    public ConfigWriteResult saveOverride(String optionKey, String value) {
        PlayerbotConfigOption option = findOption(optionKey);
        if (option == null) {
            return ConfigWriteResult.failed("Unknown Playerbots option.");
        }

        String cleanValue = value == null ? "" : value.strip();
        if (cleanValue.isBlank()) {
            return removeOverride(optionKey);
        }
        if (cleanValue.contains("\n") || cleanValue.contains("\r")) {
            return ConfigWriteResult.failed("Values cannot contain newlines.");
        }

        try {
            Map<String, String> overrides = readOverrideValues();
            overrides.put(option.primaryEnvName(), cleanValue);
            writeOverrideValues(overrides);
            writeGeneratedConfig(overrides);
            return ConfigWriteResult.ok("Saved override for " + option.key() + ".");
        } catch (IOException ex) {
            return ConfigWriteResult.failed("Could not save override: " + ex.getMessage());
        }
    }

    public ConfigWriteResult saveOverrides(List<String> optionKeys, List<String> values, List<String> originalValues) {
        if (optionKeys == null || values == null || originalValues == null
                || optionKeys.size() != values.size() || optionKeys.size() != originalValues.size()) {
            return ConfigWriteResult.failed("Could not save overrides: submitted config values were incomplete.");
        }

        PlayerbotConfigView config = load();
        Map<String, PlayerbotConfigOption> optionsByKey = new LinkedHashMap<>();
        for (PlayerbotConfigOption option : config.options()) {
            optionsByKey.put(option.key(), option);
        }

        try {
            Map<String, String> overrides = readOverrideValues();
            int changed = 0;
            for (int index = 0; index < optionKeys.size(); index++) {
                PlayerbotConfigOption option = optionsByKey.get(optionKeys.get(index));
                if (option == null) {
                    return ConfigWriteResult.failed("Unknown Playerbots option.");
                }

                String cleanValue = clean(values.get(index));
                String originalValue = clean(originalValues.get(index));
                if (cleanValue.equals(originalValue)) {
                    continue;
                }
                if (cleanValue.contains("\n") || cleanValue.contains("\r")) {
                    return ConfigWriteResult.failed("Values cannot contain newlines.");
                }

                if (cleanValue.isBlank() || cleanValue.equals(option.defaultValue())) {
                    overrides.remove(option.primaryEnvName());
                } else {
                    overrides.put(option.primaryEnvName(), cleanValue);
                }
                changed++;
            }

            if (changed == 0) {
                return ConfigWriteResult.ok("No config changes to save.");
            }

            writeOverrideValues(overrides);
            writeGeneratedConfig(overrides);
            return ConfigWriteResult.ok("Saved " + changed + " Playerbots config change" + (changed == 1 ? "." : "s."));
        } catch (IOException ex) {
            return ConfigWriteResult.failed("Could not save overrides: " + ex.getMessage());
        }
    }

    public ConfigWriteResult removeOverride(String optionKey) {
        PlayerbotConfigOption option = findOption(optionKey);
        if (option == null) {
            return ConfigWriteResult.failed("Unknown Playerbots option.");
        }

        try {
            Map<String, String> overrides = readOverrideValues();
            if (overrides.remove(option.primaryEnvName()) == null) {
                return ConfigWriteResult.ok("No dashboard override was set for " + option.key() + ".");
            }
            writeOverrideValues(overrides);
            writeGeneratedConfig(overrides);
            return ConfigWriteResult.ok("Removed dashboard override for " + option.key() + ".");
        } catch (IOException ex) {
            return ConfigWriteResult.failed("Could not remove override: " + ex.getMessage());
        }
    }

    private PlayerbotConfigOption findOption(String optionKey) {
        if (optionKey == null || optionKey.isBlank()) {
            return null;
        }
        return load().options().stream()
                .filter(option -> option.key().equals(optionKey))
                .findFirst()
                .orElse(null);
    }

    private String clean(String value) {
        return value == null ? "" : value.strip();
    }

    private PlayerbotConfigView parse(Path path,
                                      List<String> lines,
                                      List<String> searchedPaths,
                                      Map<String, String> fileOverrides) {
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
                EnvValue envValue = envValue(envNames, fileOverrides);
                options.add(new PlayerbotConfigOption(
                        section,
                        key,
                        defaultValue,
                        envValue.value() == null ? defaultValue : envValue.value(),
                        envValue.name(),
                        envValue.source(),
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

    private EnvValue envValue(List<String> names, Map<String, String> fileOverrides) {
        for (String name : names) {
            String value = fileOverrides.get(name);
            if (value != null) {
                return new EnvValue(name, value, "dashboard");
            }
        }

        Map<String, String> env = System.getenv();
        for (String name : names) {
            String value = env.get(name);
            if (value != null) {
                return new EnvValue(name, value, "environment");
            }
        }
        return new EnvValue(null, null, null);
    }

    private Map<String, String> readOverrideValues() {
        Path path = overrideEnvPath();
        if (!Files.isRegularFile(path)) {
            return new LinkedHashMap<>();
        }

        Map<String, String> values = new LinkedHashMap<>();
        try {
            for (String line : Files.readAllLines(path, StandardCharsets.UTF_8)) {
                String trimmed = line.strip();
                if (trimmed.isBlank() || trimmed.startsWith("#")) {
                    continue;
                }
                int separator = trimmed.indexOf('=');
                if (separator <= 0) {
                    continue;
                }
                String key = trimmed.substring(0, separator).strip();
                String value = trimmed.substring(separator + 1).strip();
                if (key.matches("[A-Z0-9_]+")) {
                    values.put(key, value);
                }
            }
        } catch (IOException ignored) {
            return new LinkedHashMap<>();
        }
        return values;
    }

    private void writeOverrideValues(Map<String, String> values) throws IOException {
        Path path = overrideEnvPath();
        Path parent = path.getParent();
        if (parent != null) {
            Files.createDirectories(parent);
        }

        List<String> lines = new ArrayList<>();
        lines.add("# Managed by WoW Admin Dashboard. Restart ac-worldserver after changing values.");
        values.entrySet().stream()
                .sorted(Comparator.comparing(entry -> entry.getKey()))
                .forEach(entry -> lines.add(entry.getKey() + "=" + entry.getValue()));
        Files.write(path, lines, StandardCharsets.UTF_8);
    }

    private void writeGeneratedConfig(Map<String, String> overrides) throws IOException {
        Path source = readableConfigPath();
        if (source == null) {
            throw new IOException("No readable Playerbots config template found.");
        }

        Path target = generatedConfigPath();
        Path parent = target.getParent();
        if (parent != null) {
            Files.createDirectories(parent);
        }

        List<String> generated = new ArrayList<>();
        for (String line : Files.readAllLines(source, StandardCharsets.UTF_8)) {
            Matcher option = OPTION.matcher(line.strip());
            if (option.matches()) {
                List<String> envNames = envNames(option.group(1));
                String override = envNames.stream()
                        .map(overrides::get)
                        .filter(value -> value != null)
                        .findFirst()
                        .orElse(null);
                if (override != null) {
                    generated.add(option.group(1) + " = " + override);
                    continue;
                }
            }
            generated.add(line);
        }

        Files.write(target, generated, StandardCharsets.UTF_8);
    }

    private Path readableConfigPath() {
        for (String candidate : configPaths()) {
            Path path = Path.of(candidate);
            if (Files.isRegularFile(path) && Files.isReadable(path)) {
                return path;
            }
        }
        return null;
    }

    private Path overrideEnvPath() {
        String configured = properties.playerbots() == null ? null : properties.playerbots().overrideEnvPath();
        if (configured == null || configured.isBlank()) {
            configured = "/playerbot-overrides/playerbots.env";
        }
        return Path.of(configured);
    }

    private Path generatedConfigPath() {
        String configured = properties.playerbots() == null ? null : properties.playerbots().generatedConfigPath();
        if (configured == null || configured.isBlank()) {
            configured = "/playerbot-overrides/playerbots.conf";
        }
        return Path.of(configured);
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
            String overrideSource,
            List<String> envNames,
            String description) {
        public boolean overridden() {
            return overrideEnv != null;
        }

        public boolean dashboardManaged() {
            return "dashboard".equals(overrideSource);
        }

        public String primaryEnvName() {
            return envNames.isEmpty() ? "" : envNames.get(0);
        }
    }

    public record ConfigWriteResult(boolean success, String message) {
        public static ConfigWriteResult ok(String message) {
            return new ConfigWriteResult(true, message);
        }

        public static ConfigWriteResult failed(String message) {
            return new ConfigWriteResult(false, message);
        }
    }

    private record EnvValue(String name, String value, String source) {
    }
}
