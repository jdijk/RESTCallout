public interface RESTDataConversion {
    
    Object ExternalFormatToSalesforce(Object sValue);
    Object SalesforceToExternalFormat(Object oValue);

}