package ar.edu.ubp.das.mascotascbasoap.config;

import ar.edu.ubp.das.mascotascbasoap.services.IMascotasCbaWebService;
import org.apache.cxf.Bus;
import org.apache.cxf.jaxws.EndpointImpl;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ServicesConfig {

    @Value("${security.api-key}")
    private String apiKey;

    @Bean
    public EndpointImpl localidadesEndpoint(Bus bus, IMascotasCbaWebService service) {
        EndpointImpl endpoint = new EndpointImpl(bus, service);

        // Agregar el interceptor de seguridad para verificar la API Key
        endpoint.getInInterceptors().add(new ApiKeyInterceptor(apiKey));

        endpoint.publish("/localidades");
        return endpoint;
    }
}