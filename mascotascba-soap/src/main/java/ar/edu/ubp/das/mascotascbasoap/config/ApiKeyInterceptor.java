package ar.edu.ubp.das.mascotascbasoap.config;

import org.apache.cxf.binding.soap.SoapFault;
import org.apache.cxf.binding.soap.SoapMessage;
import org.apache.cxf.binding.soap.interceptor.AbstractSoapInterceptor;
import org.apache.cxf.headers.Header;
import org.apache.cxf.interceptor.Fault;
import org.apache.cxf.phase.Phase;
import org.w3c.dom.Element;

public class ApiKeyInterceptor extends AbstractSoapInterceptor {

    private final String expectedApiKey;

    public ApiKeyInterceptor(String expectedApiKey) {
        super(Phase.PRE_PROTOCOL);
        this.expectedApiKey = expectedApiKey;
    }

    @Override
    public void handleMessage(SoapMessage message) throws Fault {
        String apiKey = getApiKeyFromHeader(message);

        if (apiKey == null || !apiKey.equals(expectedApiKey)) {
            throw new SoapFault("API Key inválida o no proporcionada",
                    message.getVersion().getSender());
        }
    }

    private String getApiKeyFromHeader(SoapMessage message) {
        for (Header header : message.getHeaders()) {
            if ("apiKey".equals(header.getName().getLocalPart())) {
                Object object = header.getObject();
                if (object instanceof Element element) {
                    return element.getTextContent().trim();
                }
            }
        }
        return null;
    }
}