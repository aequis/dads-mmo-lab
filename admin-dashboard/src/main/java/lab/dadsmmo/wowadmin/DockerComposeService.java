package lab.dadsmmo.wowadmin;

import java.io.IOException;
import java.net.UnixDomainSocketAddress;
import java.net.URLEncoder;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.springframework.stereotype.Service;

@Service
public class DockerComposeService {
    private final WowAdminProperties properties;

    public DockerComposeService(WowAdminProperties properties) {
        this.properties = properties;
    }

    public boolean enabled() {
        return properties.docker() != null
                && properties.docker().enabled()
                && Files.exists(Path.of(properties.docker().socketPath()));
    }

    public ShellResult recreateWorldserver() {
        if (!enabled()) {
            return ShellResult.failed("Docker socket control is disabled.");
        }

        String container = properties.docker().worldserverContainer();
        String encoded = URLEncoder.encode(container, StandardCharsets.UTF_8).replace("+", "%20");
        String request = "POST /containers/" + encoded + "/restart?t=10 HTTP/1.1\r\n"
                + "Host: docker\r\n"
                + "Content-Length: 0\r\n"
                + "Connection: close\r\n"
                + "\r\n";

        try (SocketChannel channel = SocketChannel.open(UnixDomainSocketAddress.of(properties.docker().socketPath()))) {
            channel.write(ByteBuffer.wrap(request.getBytes(StandardCharsets.UTF_8)));
            String response = readResponse(channel);
            int status = parseStatus(response);
            if (status >= 200 && status < 300) {
                return ShellResult.ok("Worldserver restart requested.");
            }
            return ShellResult.failed("Docker restart failed with HTTP " + status + ".");
        } catch (IOException ex) {
            return ShellResult.failed("Could not contact Docker socket: " + ex.getMessage());
        }
    }

    private String readResponse(SocketChannel channel) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(8192);
        StringBuilder response = new StringBuilder();
        while (channel.read(buffer) > 0) {
            buffer.flip();
            response.append(StandardCharsets.UTF_8.decode(buffer));
            buffer.clear();
        }
        return response.toString();
    }

    private int parseStatus(String response) {
        String[] parts = response.split("\\s+", 3);
        if (parts.length < 2) {
            return 0;
        }
        try {
            return Integer.parseInt(parts[1]);
        } catch (NumberFormatException ex) {
            return 0;
        }
    }
}
