public class RESTDateJulianConversion implements RESTDataConversion {
    
    public Object ExternalFormatToSalesforce(Object sValue)
    {
        DateTime theDate = (DateTime)sValue;
         System.debug(theDate.day() + '-' + theDate.month() + '-' + theDate.year() + ' ' + thedate.hour() + ':' + theDate.minute() + ':' + thedate.second());
        Double a = Math.floor((14-theDate.month())/12);
        Double y = theDate.year() + 4800 - a;
        Double m = theDate.month() + 12*a - 3;
        
        Double JDN = theDate.day() + Math.floor((153*m + 2)/5) + (365 * y) + Math.floor(y/4) - Math.floor(y/100) + Math.floor(y/400) - 32045;
        
        Double hour= theDate.hour();
        Double minute = theDate.minute();
        Double second = theDate.second();
        
        Double JD = JDN + ((hour-12)/24) + (minute/1440) + (second/86400);
        return JD;
    }
    
    public Object SalesforceToExternalFormat(Object oValue)
    {
        Double JulianDate = (Double)oValue;
        Integer JDN = (Integer)Math.floor(JulianDate);
        Integer f = (Integer)(JDN + 1401 + Math.floor((Math.floor((4 * JDN + 274277) / 146097) * 3) / 4) -38);
        Integer e = 4 * f + 3;
        Integer g = (Integer)(Math.floor(Math.mod(e, 1461) / 4));
        Integer h = 5 * g + 2;
        Integer Day = (Integer)(Math.floor(Math.mod(h, 153) / 5) + 1);
        Integer Month = (Integer)(Math.mod((Integer)(Math.floor(h/153)+2),12) + 1);
        Integer Year = (Integer)(Math.floor(e / 1461) - 4716 + Math.floor((12+2-Month)/12));
        
        DateTime ReturnDate = DateTime.newInstance(Year, Month, Day);
        
		Double DayFraction = JulianDate - JDN;
        
        if (DayFraction >= 0.5)
        {
            ReturnDate.addDays(1);
            DayFraction -= 0.5;
        }
        Integer Seconds = (Integer)Math.Floor((24 * 60 * 60) * DayFraction);
        Integer Hours = (Integer)Math.Floor(Seconds /3600);
        Seconds = Seconds - (3600 * Hours);
        Integer Minutes = Seconds / 60;
        Seconds = Seconds - (60 * Minutes);
        Hours += 12;
        ReturnDate.addHours(Hours);
        ReturnDate.addMinutes(Minutes);
        ReturnDate.addSeconds(Seconds);
        
        return DateTime.newInstance(Year, Month, Day, Hours, Minutes, Seconds); 
    }

}