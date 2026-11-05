package synapse.common;

import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.context.annotation.Import;
import synapse.common.api.ApiMetaFactory;
import synapse.common.api.ApiResponseAdvice;
import synapse.common.exception.HttpExceptionHandler;
import synapse.common.request.RequestIdFilter;

@AutoConfiguration
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
@Import({
    RequestIdFilter.class,
    ApiMetaFactory.class,
    ApiResponseAdvice.class,
    HttpExceptionHandler.class
})
public class CommonHttpAutoConfiguration {
}
