public interface RESTMockService {
    HTTPResponse GetMockResponse(Map<String,Object> IntegrationDefinition, Map<String,Object> DataRecord);
}