package lab.dadsmmo.wowadmin;

public record ShellResult(boolean success, String message) {
    public static ShellResult ok(String message) {
        return new ShellResult(true, message);
    }

    public static ShellResult failed(String message) {
        return new ShellResult(false, message);
    }
}
