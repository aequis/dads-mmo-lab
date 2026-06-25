package lab.dadsmmo.wowadmin;

import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class AdminController {
    private static final Set<String> PLAYERBOT_COMMANDS = Set.of(
            "playerbot rndbot stats",
            "playerbot rndbot reload",
            "playerbot rndbot update",
            "playerbot rndbot init",
            "playerbot rndbot clear",
            "playerbot rndbot level",
            "playerbot rndbot refresh",
            "playerbot rndbot teleport",
            "playerbot pmon toggle",
            "playerbot pmon stack",
            "playerbot pmon tick",
            "playerbot pmon reset");

    private final DashboardService dashboardService;
    private final PlayerbotConfigService playerbotConfigService;
    private final DockerComposeService dockerComposeService;
    private final SoapCommandService soapCommandService;

    public AdminController(DashboardService dashboardService,
                           PlayerbotConfigService playerbotConfigService,
                           DockerComposeService dockerComposeService,
                           SoapCommandService soapCommandService) {
        this.dashboardService = dashboardService;
        this.playerbotConfigService = playerbotConfigService;
        this.dockerComposeService = dockerComposeService;
        this.soapCommandService = soapCommandService;
    }

    @GetMapping("/")
    public String dashboard(Model model) {
        model.addAttribute("view", dashboardService.dashboard());
        common(model);
        return "dashboard";
    }

    @GetMapping("/accounts")
    public String accounts(Model model) {
        model.addAttribute("accounts", dashboardService.accounts());
        common(model);
        return "accounts";
    }

    @GetMapping("/characters")
    public String characters(Model model) {
        model.addAttribute("characters", dashboardService.characters());
        common(model);
        return "characters";
    }

    @GetMapping("/playerbots")
    public String playerbots(Model model) {
        model.addAttribute("view", dashboardService.playerbots());
        model.addAttribute("commands", PLAYERBOT_COMMANDS);
        common(model);
        return "playerbots";
    }

    @GetMapping("/playerbots/config")
    public String playerbotConfig(Model model) {
        model.addAttribute("config", playerbotConfigService.load());
        model.addAttribute("dockerControlEnabled", dockerComposeService.enabled());
        common(model);
        return "playerbot-config";
    }

    @PostMapping("/playerbots/config/override")
    public String savePlayerbotOverride(@RequestParam String option,
                                        @RequestParam String value,
                                        RedirectAttributes redirectAttributes) {
        PlayerbotConfigService.ConfigWriteResult result = playerbotConfigService.saveOverride(option, value);
        redirectAttributes.addFlashAttribute("commandResult",
                new ShellResult(result.success(), result.message()));
        return "redirect:/playerbots/config";
    }

    @PostMapping("/playerbots/config/override/bulk")
    public String savePlayerbotOverrides(@RequestParam("option") List<String> option,
                                         @RequestParam("value") List<String> value,
                                         @RequestParam("originalValue") List<String> originalValue,
                                         RedirectAttributes redirectAttributes) {
        PlayerbotConfigService.ConfigWriteResult result =
                playerbotConfigService.saveOverrides(option, value, originalValue);
        redirectAttributes.addFlashAttribute("commandResult",
                new ShellResult(result.success(), result.message()));
        return "redirect:/playerbots/config";
    }

    @PostMapping("/playerbots/config/override/remove")
    public String removePlayerbotOverride(@RequestParam(name = "option", required = false) String option,
                                          @RequestParam(name = "resetOption", required = false) String resetOption,
                                          RedirectAttributes redirectAttributes) {
        PlayerbotConfigService.ConfigWriteResult result =
                playerbotConfigService.removeOverride(resetOption == null ? option : resetOption);
        redirectAttributes.addFlashAttribute("commandResult",
                new ShellResult(result.success(), result.message()));
        return "redirect:/playerbots/config";
    }

    @PostMapping("/playerbots/config/restart-worldserver")
    public String restartWorldserver(RedirectAttributes redirectAttributes) {
        ShellResult result = dockerComposeService.recreateWorldserver();
        redirectAttributes.addFlashAttribute("commandResult", result);
        return "redirect:/playerbots/config";
    }

    @PostMapping("/command")
    public String command(@RequestParam String command,
                          @RequestParam(defaultValue = "/") String returnTo,
                          RedirectAttributes redirectAttributes) {
        ShellResult result = soapCommandService.execute(command.strip());
        redirectAttributes.addFlashAttribute("commandResult", result);
        return "redirect:" + safeReturn(returnTo);
    }

    @PostMapping("/playerbots/command")
    public String playerbotCommand(@RequestParam String command, RedirectAttributes redirectAttributes) {
        if (!PLAYERBOT_COMMANDS.contains(command)) {
            redirectAttributes.addFlashAttribute("commandResult", ShellResult.failed("Unsupported playerbot command."));
            return "redirect:/playerbots";
        }

        ShellResult result = soapCommandService.execute(command);
        redirectAttributes.addFlashAttribute("commandResult", result);
        return "redirect:/playerbots";
    }

    @PostMapping("/accounts/create")
    public String createAccount(@RequestParam String username,
                                @RequestParam String password,
                                @RequestParam(defaultValue = "0") int gmLevel,
                                RedirectAttributes redirectAttributes) {
        String cleanUser = username.strip();
        String cleanPassword = password.strip();
        if (!cleanUser.matches("[A-Za-z0-9_@.-]{3,32}") || cleanPassword.length() < 3 || cleanPassword.length() > 64) {
            redirectAttributes.addFlashAttribute("commandResult", ShellResult.failed("Account name or password is invalid."));
            return "redirect:/accounts";
        }

        ShellResult created = soapCommandService.execute("account create " + cleanUser + " " + cleanPassword);
        if (created.success() && gmLevel > 0) {
            ShellResult promoted = soapCommandService.execute("account set gmlevel " + cleanUser + " " + Math.min(gmLevel, 3) + " -1");
            redirectAttributes.addFlashAttribute("commandResult", promoted);
        } else {
            redirectAttributes.addFlashAttribute("commandResult", created);
        }
        return "redirect:/accounts";
    }

    private void common(Model model) {
        model.addAttribute("soapEnabled", soapCommandService.enabled());
        model.addAttribute("classNames", Map.of(
                1, "Warrior", 2, "Paladin", 3, "Hunter", 4, "Rogue", 5, "Priest",
                6, "Death Knight", 7, "Shaman", 8, "Mage", 9, "Warlock", 11, "Druid"));
    }

    private String safeReturn(String returnTo) {
        if (returnTo == null || returnTo.isBlank() || !returnTo.startsWith("/") || returnTo.startsWith("//")) {
            return "/";
        }
        return returnTo;
    }
}
