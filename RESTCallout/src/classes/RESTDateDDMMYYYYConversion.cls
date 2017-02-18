public class RESTDateDDMMYYYYConversion implements RESTDataConversion {

    public Object ExternalFormatToSalesforce(Object sValue)
    {
        // 20161206T100929.831 GMT
        String sDate = (String)sValue;
        String Year = sDate.substring(7,10);
        String Month = sDate.substring(3,5);
        String Day = sDate.substring(0,1);
        
        sDate = Year + '-' + Month + '-' + Day;
        return Date.valueOf(sDate);
    }
    
    public Object SalesforceToExternalFormat(Object oValue)
    {
		Date oDate = (Date)oValue;

		String sYear = String.valueOf(oDate.year());
		String sMonth = String.valueOf(oDate.month());
        String sDay = String.valueOf(oDate.day());
        
        return sDay+sMonth+sYear;
    }
}