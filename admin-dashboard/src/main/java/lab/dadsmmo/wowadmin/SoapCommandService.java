package lab.dadsmmo.wowadmin;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;

import org.springframework.stereotype.Service;
import org.springframework.web.util.HtmlUtils;

@Service
public class SoapCommandService {
    private final WowAdminProperties properties;
    private final HttpClient httpClient;

    public SoapCommandService(WowAdminProperties properties) {
        this.properties = properties;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(3))
                .build();
    }

    public boolean enabled() {
        return properties.soap().enabled();
    }

    public ShellResult execute(String command) {
        if (!enabled()) {
            return ShellResult.failed("SOAP is not configured. Set WOW_ADMIN_SOAP_USER and WOW_ADMIN_SOAP_PASSWORD.");
        }

        String envelope = """
                <?xml version="1.0" encoding="UTF-8"?>
                <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                                   xmlns:ns1="urn:AC">
                  <SOAP-ENV:Body>
                    <ns1:executeCommand>
                      <command>%s</command>
                    </ns1:executeCommand>
                  </SOAP-ENV:Body>
                </SOAP-ENV:Envelope>
                """.formatted(HtmlUtils.htmlEscape(command));

        String auth = properties.soap().username() + ":" + properties.soap().password();
        HttpRequest request = HttpRequest.newBuilder(URI.create(properties.soap().url()))
                .timeout(Duration.ofSeconds(10))
                .header("Authorization", "Basic " + Base64.getEncoder().encodeToString(auth.getBytes(StandardCharsets.UTF_8)))
                .header("Content-Type", "text/xml; charset=utf-8")
                .POST(HttpRequest.BodyPublishers.ofString(envelope, StandardCharsets.UTF_8))
                .build();

        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                return ShellResult.ok(stripSoap(response.body()));
            }
            return ShellResult.failed("SOAP returned HTTP " + response.statusCode() + ": " + stripSoap(response.body()));
        } catch (IOException e) {
            return ShellResult.failed("SOAP request failed: " + e.getMessage());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return ShellResult.failed("SOAP request interrupted.");
        }
    }

    private String stripSoap(String body) {
        if (body == null || body.isBlank()) {
            return "Command sent.";
        }
        return body.replaceAll("<[^>]+>", " ")
                .replaceAll("\\s+", " ")
                .trim();
    }
}
