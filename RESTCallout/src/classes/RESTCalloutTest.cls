@isTest
private class RESTCalloutTest {
    @isTest
    static void testRESTCallout() {
        Test.setMock(HttpCalloutMock.class, new RESTCalloutMock());
        
        Test.startTest();
         Integration_Target__c IntTarget = new Integration_Target__c();
        
        IntTarget.Name = 'Test Target';
        IntTarget.Named_Credentials__c = 'Test';
        IntTarget.User_Field_Name__c = 'UserName';
        
        Insert IntTarget;
        
        Integration_Definition__c IntDef = new Integration_Definition__c();
        
        IntDef.Integration_Target__c = IntTarget.Id;
        IntDef.Name = 'Blacklist';
        IntDef.External_Object__c = false;
        IntDef.HTTP_Method__c = 'GET';
        IntDef.Integration_User__c = false;
        IntDef.URL_Method__c = 'Test';
        IntDef.Object__c = 'Contact';
        
        Insert IntDef;
        
        Integration_Output__c IntOutput = new Integration_Output__c();
        IntOutput.Name = 'first_name';
        IntOutput.Field_Name__c = 'FirstName';
        IntOutput.Field_Type__c = 'Text';
        IntOutput.Header_Variable__c = false;
        IntOUtput.Integration_Definition__c = IntDef.Id;
        Insert IntOutput;
        
        IntOutput = new Integration_Output__c();
        IntOutput.Name = 'last_name';
        IntOutput.Field_Name__c = 'LastName';
        IntOutput.Field_Type__c = 'Text';
        IntOutput.Header_Variable__c = false;
        IntOUtput.Integration_Definition__c = IntDef.Id;
        Insert IntOutput;
        
        IntOutput = new Integration_Output__c();
        IntOutput.Name = 'BirthPlace';
        IntOutput.Field_Name__c = 'Birth_Town__c';
        IntOutput.Field_Type__c = 'Text';
        IntOutput.Header_Variable__c = true;
        IntOUtput.Integration_Definition__c = IntDef.Id;

        Insert IntOutput;
        
        Integration_Input__c IntInput = new Integration_Input__c();
        IntInput.Name = 'FirstName';
        IntInput.Field_Name__c = 'FirstName';
        IntInput.Field_Type__c = 'Text';
        IntInput.Integration_Definition__c = IntDef.Id;
        IntInput.Fixed__c = false;
        IntInput.Type__c = 'Body';
        Insert IntInput;
   
        IntInput = new Integration_Input__c();
        IntInput.Name = 'FirstName2';
        IntInput.Field_Name__c = 'FirstName';
        IntInput.Field_Type__c = 'Text';
        IntInput.Integration_Definition__c = IntDef.Id;
        IntInput.Fixed__c = false;
        IntInput.Type__c = 'Header';
        Insert IntInput;
  
        IntInput = new Integration_Input__c();
        IntInput.Name = 'Customer.FirstName3';
        IntInput.Field_Name__c = 'FirstName';
        IntInput.Field_Type__c = 'Text';
        IntInput.Integration_Definition__c = IntDef.Id;
        IntInput.Fixed__c = false;
        IntInput.Type__c = 'Body';
        Insert IntInput;
        
        
  
        
        Contact c = new Contact();
        // c.RecordTypeId = '0120Y000000XvWbQAK';
       
        c.FirstName = 'Jack';
        c.LastName = 'van Dijk';
        
        Insert c;
        
        List<Contact> Contacts = [select FirstName, LastName from Contact where Id = :c.ID];
        
        System.assertEquals(1, Contacts.size());
 
        
        RESTDataSourceProvider RESTDP = new RESTDataSourceProvider();
        
        RESTDP.getCapabilities();
        RESTDP.getAuthenticationCapabilities();
        RESTDP.getConnection(null);
        
        Test.stopTest();
   
      
    }

}