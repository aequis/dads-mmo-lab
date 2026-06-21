package lab.dadsmmo.wowadmin;

import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class DashboardService {
    private final JdbcTemplate jdbc;
    private final WowAdminProperties properties;

    public DashboardService(JdbcTemplate jdbc, WowAdminProperties properties) {
        this.jdbc = jdbc;
        this.properties = properties;
    }

    public DashboardView dashboard() {
        String auth = db(properties.databases().auth());
        String chars = db(properties.databases().characters());
        String bots = db(properties.databases().playerbots());

        Map<String, Object> totals = jdbc.queryForMap("""
                SELECT
                  (SELECT COUNT(*) FROM %s.account) AS accounts,
                  (SELECT COUNT(*) FROM %s.characters WHERE deleteDate IS NULL) AS characters,
                  (SELECT COUNT(*) FROM %s.characters WHERE online = 1) AS onlineCharacters,
                  (SELECT COUNT(DISTINCT bot) FROM %s.playerbots_random_bots) AS randomBots
                """.formatted(auth, chars, chars, bots));

        List<Map<String, Object>> onlinePlayers = jdbc.queryForList("""
                SELECT c.name, c.level, c.race, c.class, c.zone, c.map, a.username
                FROM %s.characters c
                JOIN %s.account a ON a.id = c.account
                WHERE c.online = 1
                ORDER BY c.level DESC, c.name
                LIMIT 50
                """.formatted(chars, auth));

        List<Map<String, Object>> recentAccounts = jdbc.queryForList("""
                SELECT a.id, a.username, a.joindate, a.last_login, a.online,
                       COALESCE(MAX(aa.gmlevel), 0) AS gmlevel
                FROM %s.account a
                LEFT JOIN %s.account_access aa ON aa.id = a.id
                GROUP BY a.id, a.username, a.joindate, a.last_login, a.online
                ORDER BY a.joindate DESC
                LIMIT 12
                """.formatted(auth, auth));

        List<Map<String, Object>> classBreakdown = jdbc.queryForList("""
                SELECT class, COUNT(*) AS total
                FROM %s.characters
                WHERE deleteDate IS NULL
                GROUP BY class
                ORDER BY total DESC
                """.formatted(chars));

        return new DashboardView(totals, onlinePlayers, recentAccounts, classBreakdown);
    }

    public PlayerbotView playerbots() {
        String chars = db(properties.databases().characters());
        String bots = db(properties.databases().playerbots());

        List<Map<String, Object>> levelBands = jdbc.queryForList("""
                SELECT
                  CASE
                    WHEN c.level < 10 THEN '01-09'
                    WHEN c.level < 20 THEN '10-19'
                    WHEN c.level < 30 THEN '20-29'
                    WHEN c.level < 40 THEN '30-39'
                    WHEN c.level < 50 THEN '40-49'
                    WHEN c.level < 60 THEN '50-59'
                    WHEN c.level < 70 THEN '60-69'
                    ELSE '70-80'
                  END AS band,
                  COUNT(*) AS total
                FROM (SELECT DISTINCT bot FROM %s.playerbots_random_bots) rb
                JOIN %s.characters c ON c.guid = rb.bot
                GROUP BY band
                ORDER BY band
                """.formatted(bots, chars));

        List<Map<String, Object>> botClasses = jdbc.queryForList("""
                SELECT c.class, COUNT(*) AS total, ROUND(AVG(c.level), 1) AS averageLevel
                FROM (SELECT DISTINCT bot FROM %s.playerbots_random_bots) rb
                JOIN %s.characters c ON c.guid = rb.bot
                GROUP BY c.class
                ORDER BY total DESC
                """.formatted(bots, chars));

        List<Map<String, Object>> sampleBots = jdbc.queryForList("""
                SELECT c.guid, c.name, c.level, c.race, c.class, c.zone, c.map, c.money, c.online
                FROM (SELECT DISTINCT bot FROM %s.playerbots_random_bots) rb
                JOIN %s.characters c ON c.guid = rb.bot
                ORDER BY c.level DESC, c.name
                LIMIT 100
                """.formatted(bots, chars));

        Map<String, Object> totals = jdbc.queryForMap("""
                SELECT
                  COUNT(DISTINCT rb.bot) AS randomBots,
                  COALESCE(SUM(c.online = 1), 0) AS onlineBots,
                  ROUND(AVG(c.level), 1) AS averageLevel,
                  MAX(c.level) AS highestLevel
                FROM (SELECT DISTINCT bot FROM %s.playerbots_random_bots) rb
                JOIN %s.characters c ON c.guid = rb.bot
                """.formatted(bots, chars));

        return new PlayerbotView(totals, levelBands, botClasses, sampleBots);
    }

    public List<Map<String, Object>> accounts() {
        String auth = db(properties.databases().auth());
        return jdbc.queryForList("""
                SELECT a.id, a.username, a.email, a.joindate, a.last_login, a.last_ip,
                       a.online, a.locked, a.mutetime, COALESCE(MAX(aa.gmlevel), 0) AS gmlevel
                FROM %s.account a
                LEFT JOIN %s.account_access aa ON aa.id = a.id
                GROUP BY a.id, a.username, a.email, a.joindate, a.last_login, a.last_ip,
                         a.online, a.locked, a.mutetime
                ORDER BY a.username
                LIMIT 250
                """.formatted(auth, auth));
    }

    public List<Map<String, Object>> characters() {
        String auth = db(properties.databases().auth());
        String chars = db(properties.databases().characters());
        return jdbc.queryForList("""
                SELECT c.guid, c.name, c.level, c.race, c.class, c.zone, c.map,
                       c.money, c.online, c.totaltime, a.username
                FROM %s.characters c
                JOIN %s.account a ON a.id = c.account
                WHERE c.deleteDate IS NULL
                ORDER BY c.online DESC, c.level DESC, c.name
                LIMIT 250
                """.formatted(chars, auth));
    }

    private String db(String name) {
        if (name == null || !name.matches("[A-Za-z0-9_]+")) {
            throw new IllegalArgumentException("Invalid database name: " + name);
        }
        return "`" + name + "`";
    }

    public record DashboardView(
            Map<String, Object> totals,
            List<Map<String, Object>> onlinePlayers,
            List<Map<String, Object>> recentAccounts,
            List<Map<String, Object>> classBreakdown) {
    }

    public record PlayerbotView(
            Map<String, Object> totals,
            List<Map<String, Object>> levelBands,
            List<Map<String, Object>> classBreakdown,
            List<Map<String, Object>> sampleBots) {
    }
}
