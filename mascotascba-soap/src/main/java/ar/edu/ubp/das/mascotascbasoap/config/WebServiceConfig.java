package ar.edu.ubp.das.mascotascbasoap.config;

import ar.edu.ubp.das.mascotascbasoap.services.IMascotasCbaWebService;
import org.apache.cxf.Bus;
import org.apache.cxf.jaxws.EndpointImpl;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class WebServiceConfig {

    private final Bus bus;
    private final IMascotasCbaWebService mascotasWebService;

    @Value("${security.api-key}")
    private String apiKey;

    public WebServiceConfig(Bus bus, IMascotasCbaWebService mascotasWebService) {
        this.bus = bus;
        this.mascotasWebService = mascotasWebService;
    }

    @Bean
    public EndpointImpl endpoint() {
        EndpointImpl endpoint = new EndpointImpl(bus, mascotasWebService);

        endpoint.getInInterceptors().add(new ApiKeyInterceptor(apiKey));

        endpoint.publish("/integracion");

        return endpoint;
    }
}