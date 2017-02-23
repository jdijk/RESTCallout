/**************************************************************/
//  
// Class name: RESTCallOut
// 
// This class is used to do the generic REST callouts
// 
// Author: Jack van Dijk
/**************************************************************/


public class RESTCallOut {
    public static final String STRUCTURE_INPUTS = 'Integration_Inputs__r';
    public static final String STRUCTURE_OUTPUTS = 'Integration_Outputs__r';
    public static final String STRUCTURE_TARGET = 'Integration_Target__r';
    public static final String STRUCTURE_OBJECT = 'Object__c';
    public static final String STRUCTURE_NAMED_CREDENTIALS = 'Named_Credentials__c';
    public static final String STRUCTURE_HEADER_VARIABLE = 'Header_Variable__c';
    public static final String STRUCTURE_URL_METHOD = 'URL_Method__c';
    public static final String STRUCTURE_HTTP_METHOD = 'HTTP_Method__c';
    public static final String STRUCTURE_NAMESPACE = 'Namespace__c';
    public static final String STRUCTURE_COLLECTION = 'Collection_Name__c';
    public static final String STRUCTURE_VERSION = 'Version__c';
    public static final String STRUCTURE_UID_FIELD = 'User_Field_Name__c';
    public static final String STRUCTURE_UID_VALUE = 'Integration_User__c';
    public static final String STRUCTURE_NAME = 'Name';
    public static final String STRUCTURE_VALUE = 'Value';
    public static final String STRUCTURE_FIELD_NAME = 'Field_Name__c';
    public static final String STRUCTURE_FIELD_TYPE = 'Field_Type__c';
    public static final String STRUCTURE_FIELD_CONVERSION = 'Field_Conversion__c';
    public static final String STRUCTURE_FIELD_CONVERSION_CUSTOM = 'Field_Conversion_Custom__c';
    public static final String STRUCTURE_FIXED = 'Fixed__c';
    public static final String STRUCTURE_FIXED_VALUE = 'Fixed_Value__c';
    public static final String STRUCTURE_RECORDS = 'records';
    public static final String STRUCTURE_TOTALSIZE = 'totalSize';
    public static final String STRUCTURE_QUERY = 'Query';
    public static final String STRUCTURE_IDS = 'IDS';
    public static final String STRUCTURE_DATA = 'Data';
    public static final String STRUCTURE_SYNCHRONOUS = 'Synchronous__c';
    public static final String STRUCTURE_TYPE = 'Type__c';
    public static final String STRUCTURE_EXTERNAL_ID = 'External_Id__c';
    public static final String STRUCTURE_USE_MOCK = 'Use_Mock_Class__c';
    public static final String STRUCTURE_MOCK_CLASS = 'Mock_Class_Name__c';
    public static final String STRUCTURE_EXTERNAL_OBJECT = 'External_Object__c';
    
    public static final String ARGUMENT_TYPE_HEADER = 'Header';
    public static final String ARGUMENT_TYPE_URI = 'URI';
    public static final String ARGUMENT_TYPE_QUERY_PARAMETER = 'Query Parameter';
    public static final String ARGUMENT_TYPE_BODY = 'Body';
  
    public static final String FIELD_TYPE_BOOLEAN = 'Boolean';
    public static final String FIELD_TYPE_NUMBER = 'Number';
    public static final String FIELD_TYPE_DATE = 'Date';
    public static final String FIELD_TYPE_BOOLEAN_TRUE = 'Yes';
    public static final String FIELD_TYPE_BOOLEAN_FALSE = 'No';
    
    public static final String FIELD_CONVERSION_CUSTOM = 'Custom';
    public static final String FIELD_CONVERSION_DATE_JULIAN = 'Julian Date';
    public static final String FIELD_CONVERSION_DATE_DDMMYYYY = 'DD/MM/YYYY';
    public static final String FIELD_CONVERSION_DATE_MMDDYYYY = 'MM/DD/YYYY';
    public static final String FIELD_CONVERSION_BOOLEAN_Y_N = 'Y/N';
    public static final String FIELD_CONVERSION_BOOLEAN_TRUE_FALSE = 'True/False';
    
    
    public static final String HTTP_METHOD_POST = 'POST';
    
    public static final String URL_ENCODING = 'UTF-8';
    
    //
    // This is the method being called from the Proces Builder    
    //        
    // Inputs: InputData, this is an array of Strings. The Process Builder can only send a single string to the Apex, but 
    // because of the bulkify functionality we need to assume an array of strings coming in.
    //              
    @InvocableMethod(Label='Perform REST Call' description='Perform a REST call')
    public static void ProcessBuilderRESTCall(List<String> InputData) {
        
        List<String> Methods = new List<String>();
        List<String> IDs = new List<String>();
        
        // Loop through all the items to process.
        for (String Inputs : InputData)
        {
            String[] Values;
            if (Inputs.indexOf('.') >= 0)
            {
                Values = Inputs.split('\\.');
                IDs.add(Values[0]);
                Methods.add(Values[1]);
            }
        }
        Map<String,Object> IntegrationDefs = LoadIntegrationStructure(Methods);
        
        if (IntegrationDefs != null)
        {
            SetIds(IntegrationDefs, Methods, IDs);
            FinalizeObjectQueries(IntegrationDefs);
            LoadObjectData(IntegrationDefs);
            PerformRESTCalls(IntegrationDefs);
       
        }
    }
    
    //
    // Perform an ASync REST call
    // 
    @future (callout=true)
    public static void PerformRESTCallAsync(String IntegrationStructureJSON)
    {
        Map<String,Object> IntegrationStructure = (Map<String,Object>)JSON.deserializeUntyped(IntegrationStructureJSON);
        PerformRestCall(IntegrationStructure);
        System.Debug('Async: ' + json.serialize(IntegrationStructure));
        SaveObjectData(IntegrationStructure);
        System.Debug('All done');
    }
    
    // 
    // Perform REST calls for all the records in the dataset
    // 
    public static void PerformRESTCall(Map<String,Object> IntDef)
    {
        List<Object> DataRecords = (List<Object>)IntDef.get(STRUCTURE_DATA);
        
        for (Integer i=0; i < DataRecords.size(); i++)
        {
            Map<String,Object> DataRecord = (Map<String,Object>)DataRecords[i];
            PerformSingleRESTCall(IntDef, DataRecord);
            System.Debug(Json.serialize(IntDef));
        }
    }
    
    public static void PrepareInput(Map<String,Object> IntDef, Map<String,Object> DataRecord, HttpRequest req)
    {
        String URI = 'callout:';
        String QueryParameters = '';
        Map<String,Object> outboundContentMap = new Map<String,Object>();
       
        Map<String,Object> IntegrationTarget = (Map<String,Object>)IntDef.Get(STRUCTURE_TARGET);
        URI += (String)IntegrationTarget.get(STRUCTURE_NAMED_CREDENTIALS) + '/';
        URI += (String)IntDef.get(STRUCTURE_URL_METHOD);
        
        String userIdentifier = UserInfo.getUserName();
        
        if ((Boolean)IntDef.get(STRUCTURE_UID_VALUE))
            userIdentifier = (String)IntegrationTarget.get(STRUCTURE_UID_VALUE);
        
        Map<String,Object> Inputs = (Map<String,Object>)IntDef.get(STRUCTURE_INPUTS);
        
        if ((Integer)Inputs.get(STRUCTURE_TOTALSIZE) > 0)
        {
            List<Object> InputRecords = (List<Object>)Inputs.get(STRUCTURE_RECORDS);
            
            for (Integer i = 0; i < InputRecords.size(); i++)
            {
                Map<String,Object> InputRecord = (Map<String,Object>)InputRecords[i];
                
                if ((String)InputRecord.get(STRUCTURE_TYPE) == ARGUMENT_TYPE_HEADER)
                {
                    if ((Boolean)InputRecord.get(STRUCTURE_FIXED))
                        req.setHeader((String)InputRecord.get(STRUCTURE_NAME), (String)InputRecord.get(STRUCTURE_FIXED_VALUE));
                    else
                    {
                        if (((String)InputRecord.get(STRUCTURE_FIELD_NAME)).indexOf('.') >= 0)
                        {
                            String[] FieldNames = ((String)InputRecord.get(STRUCTURE_FIELD_NAME)).split('\\.');
                            Map<String,Object> ChildRecord = (Map<String,Object>)DataRecord.get(FieldNames[0]);
                            req.setHeader((String)InputRecord.get(STRUCTURE_NAME), GetFieldValue(ChildRecord.get(FieldNames[1]),(String)InputRecord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION),(String)InputRecord.Get(STRUCTURE_FIELD_CONVERSION_CUSTOM)));
                            // handle child object
                        }
                        else
                            req.setHeader((String)InputRecord.get(STRUCTURE_NAME), GetFieldValue(DataRecord.get((String)InputRecord.get(STRUCTURE_FIELD_NAME)), (String)InputRecord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION_CUSTOM)));
                    }
                }
                else if ((String)InputRecord.get(STRUCTURE_TYPE) == ARGUMENT_TYPE_QUERY_PARAMETER)
                {
                     if ((Boolean)InputRecord.get(STRUCTURE_FIXED))
                         QueryParameters += '&' + (String)InputRecord.get(STRUCTURE_NAME) + '=' + EncodingUtil.urlEncode((String)InputRecord.get(STRUCTURE_FIXED_VALUE), URL_ENCODING);
                     else
                     {
                         if (((String)InputRecord.get(STRUCTURE_FIELD_NAME)).indexOf('.') >= 0)
                         {
                            // handle child object
                            String[] FieldNames = ((String)InputRecord.get(STRUCTURE_FIELD_NAME)).split('\\.');
                            Map<String,Object> ChildRecord = (Map<String,Object>)DataRecord.get(FieldNames[0]);
                            QueryParameters += '&' + (String)InputRecord.get(STRUCTURE_NAME) + '=' +  EncodingUtil.urlEncode(GetFieldValue(ChildRecord.get(FieldNames[1]),(String)InputRecord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION_CUSTOM)), URL_ENCODING);
                        }
                         else
                            QueryParameters += '&' +  (String)InputRecord.get(STRUCTURE_NAME) + '=' + EncodingUtil.urlEncode(GetFieldValue(DataRecord.get((String)InputRecord.get(STRUCTURE_FIELD_NAME)),(String)InputREcord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION_CUSTOM) ), URL_ENCODING);
                     }
                }
                else if ((String)InputRecord.get(STRUCTURE_TYPE) == ARGUMENT_TYPE_URI)
                {
                    if ((Boolean)InputRecord.get(STRUCTURE_FIXED))
                        URI += '/' + EncodingUtil.urlEncode((String)InputRecord.get(STRUCTURE_FIXED_VALUE), URL_ENCODING);
                    else
                    {
                        if (((String)InputRecord.get(STRUCTURE_FIELD_NAME)).indexOf('.') >= 0)
                        {
                            // handle child object
                            String[] FieldNames = ((String)InputRecord.get(STRUCTURE_FIELD_NAME)).split('\\.');
                            Map<String,Object> ChildRecord = (Map<String,Object>)DataRecord.get(FieldNames[0]);
                            URI += '/' +  EncodingUtil.urlEncode(GetFieldValue(ChildRecord.get(FieldNames[1]),(String)InputRecord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION_CUSTOM)), URL_ENCODING);
                        }
                        else
                            URI += '/' + EncodingUtil.urlEncode(GetFieldValue(DataRecord.get((String)InputRecord.get(STRUCTURE_FIELD_NAME)),(String)InputRecord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION_CUSTOM)), URL_ENCODING);  
                    }
                }
                else
                {
                    if (((String)InputRecord.get(STRUCTURE_NAME)).indexOf('.') > 0)
                    {
                        Map<string, String> Child;
                        String[] Names = ((String)InputRecord.get(STRUCTURE_NAME)).split('\\.');
                        if (outboundContentMap.get(Names[0]) == null)
                        {
                            Child = new Map<String,String>();
                            outboundContentMap.put(Names[0], Child);
                        }
                        else
                            Child = (Map<String,String>)outboundContentMap.get(Names[0]);
                        
                        if ((Boolean)InputRecord.get(STRUCTURE_FIXED))
                            Child.put(Names[1], (String)InputRecord.get(STRUCTURE_FIXED_VALUE));
                        else
                        {
                            if (((String)InputRecord.get(STRUCTURE_FIELD_NAME)).indexOf('.') >= 0)
                            {
                                String[] FieldNames = ((String)InputRecord.get(STRUCTURE_FIELD_NAME)).split('\\.');
                                Map<String,Object> ChildRecord = (Map<String,Object>)DataRecord.get(FieldNames[0]);
                                Child.put(Names[1], GetFieldValue(ChildRecord.get(FieldNames[1]), (String)InputRecord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION_CUSTOM)  ));
                                // handle child object
                            }
                            else
                                Child.put(Names[1], GetFieldValue(DataRecord.get((String)InputRecord.get(STRUCTURE_FIELD_NAME)), (String)InputRecord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION),(String)InputRecord.get(STRUCTURE_FIELD_CONVERSION_CUSTOM)  ));
                        }
                    
                    }
                    else
                    {
                        if ((Boolean)InputRecord.get(STRUCTURE_FIXED))
                            outboundContentMap.put((String)InputRecord.get(STRUCTURE_NAME), (String)InputRecord.get(STRUCTURE_FIXED_VALUE));
                        else
                        {
                            if (((String)InputRecord.get(STRUCTURE_FIELD_NAME)).indexOf('.') >= 0)
                            {
                                String[] FieldNames = ((String)InputRecord.get(STRUCTURE_FIELD_NAME)).split('\\.');
                                Map<String,Object> ChildRecord = (Map<String,Object>)DataRecord.get(FieldNames[0]);
                                outboundContentMap.put((String)InputRecord.get(STRUCTURE_NAME), GetFieldValue(ChildRecord.get(FieldNames[1]), (String)InputRecord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION),(String)InputRecord.get(STRUCTURE_FIELD_CONVERSION_CUSTOM)  ));
                                // handle child object
                            }
                            else
                                outboundContentMap.put((String)InputRecord.get(STRUCTURE_NAME), GetFieldValue(DataRecord.get((String)InputRecord.get(STRUCTURE_FIELD_NAME)), (String)InputRecord.get(STRUCTURE_FIELD_TYPE), (String)InputRecord.get(STRUCTURE_FIELD_CONVERSION),(String)InputRecord.get(STRUCTURE_FIELD_CONVERSION_CUSTOM)  ));
                        }
                        
                    }
                }
            }
            
        }
        
        if (IntegrationTarget.get(STRUCTURE_UID_FIELD) == null)
        {
            if (QueryParameters.length() > 0)
                URI += '?' + QueryParameters.substring(1);
        }
        else
            URI += '?' + (String)IntegrationTarget.get(STRUCTURE_UID_FIELD) + '=' + userIdentifier + QueryParameters;
        System.debug(URI);
        req.setEndpoint(URI);
        if (outboundContentMap.size() > 0)
        {         
            String outboundContentJSON = JSON.serialize(outboundContentMap);
            System.Debug(outboundContentJSON);
            req.setBody(outboundContentJSON);
            //if ((String)IntDef.get(STRUCTURE_HTTP_METHOD) == HTTP_METHOD_POST)
                //req.setHeader('Content-Length',String.valueOf(outboundContentJSON.length()));
        }
        req.setMethod((String)IntDef.get(STRUCTURE_HTTP_METHOD));
       
        
    }
    
    // Do the actual REST call for a single data record
    // 
    public static Boolean PerformSingleRESTCall(Map<String,Object> IntDef, Map<String,Object> DataRecord)
    {
        Boolean ReturnValue = false;
        String URI = 'callout:';
        HttpRequest req = new HttpRequest();
        
        PrepareInput(IntDef, DataRecord, req);
       
       	HTTPResponse res;
        
        // Decide if we do a real call or call a mock class.
        if ((Boolean)IntDef.get(STRUCTURE_USE_MOCK))
        {
        	RESTMockService TheMock;
        	Type mockType = Type.forName((String)IntDef.get(STRUCTURE_MOCK_CLASS));
        	if (null != mockType)
        	{
        		TheMock = (RESTMockService) mockType.newInstance();
        	    res = TheMock.GetMockResponse(IntDef, DataRecord);
        	    res.setStatusCode(200);
        	}
        	else
        	{
        		res = new HTTPResponse();
        		res.setStatusCode(403);
        	}
        }
        else
        {
        	Http http = new Http();
            res = http.send(req);
        }
        
        System.debug('Statuscode: ' + res.getStatusCode());
        
        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300)
        {
            System.Debug(res.getBody());
            ReturnValue = true;
            Map<String,Object> resultBody;
            
            if (res.getBody().length() > 0)
                resultBody = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            else
                resultBody = new Map<String,Object>();
            
            Map<String,Object> OutputStructure = (Map<String,Object>)IntDef.get(STRUCTURE_OUTPUTS);
            
            if ((Integer)OutputStructure.get(STRUCTURE_TOTALSIZE) > 0)
            {
                List<Object> OutputArguments = (List<Object>)OutputStructure.get(STRUCTURE_RECORDS);
                
                for (Integer i = 0; i < OutputArguments.size(); i++)
                {
                    Map<String,Object> OutputArgument = (Map<String,Object>)OutputArguments[i];
                    if ((Boolean)OutputArgument.get(STRUCTURE_HEADER_VARIABLE))
                        DataRecord.put((String)OutputArgument.get(STRUCTURE_FIELD_NAME), res.getHeader((String)OutputArgument.get(STRUCTURE_NAME)));
                    else
                        DataRecord.put((String)OutputArgument.get(STRUCTURE_FIELD_NAME), resultBody.get((String)OutputArgument.get(STRUCTURE_NAME)));      
                }
            }
            IntDef.put('Result', 'true');
            System.Debug('SingleRESTCall' + JSON.serialize(DataRecord));
        }
        else
            IntDef.put('Result', 'false');
        
        return ReturnValue;
    }
    
    //
    // Do the rest calls for all the integrations
    // 
    public static void PerformRESTCalls(Map<String,Object> IntegrationStructure)
    {
        for (String key : IntegrationStructure.keySet())
        {
            Map<String,Object> IntDef = (Map<String,Object>)IntegrationStructure.get(key);
            
            if ((Boolean)IntDef.get(STRUCTURE_SYNCHRONOUS))
            {
                PerformRESTCall(IntDef);
                SaveObjectData(IntDef);
            }
            else
            {
                PerformRESTCallAsync(JSON.serialize(IntDef));
            }   
        }
    }
    
    //
    // Store the return data in the database
    // 
    public static Boolean SaveObjectData(Map<String,Object> IntDef)
    {
        List<SObject> Records = new List<SObject>(); 
        List<Object> DataRecords = (List<Object>)IntDef.get(STRUCTURE_DATA);
        
        System.Debug(JSON.serialize(IntDef));
        if (DataRecords != null && DataRecords.size() > 0 && IntDef.get('Result') != 'false')
        {
            
            for (Integer i = 0; i < DataRecords.size(); i++)
            {
                Map<String,Object> DataRecord = (Map<String,Object>)DataRecords[i];
                SObject UpdateRecord = Schema.getGlobalDescribe().get((String)IntDef.get(STRUCTURE_OBJECT)).newSObject();
                
                UpdateRecord.put('Id', (String)DataRecord.get('Id'));
                
                Map<String,Object> OutputStructure = (Map<String,Object>)IntDef.get(STRUCTURE_OUTPUTS);
                
                if ((Integer)OutputStructure.get(STRUCTURE_TOTALSIZE) > 0)
                {
                    List<Object> OutputArguments = (List<Object>)OutputStructure.get(STRUCTURE_RECORDS);
                    for (Integer Teller = 0; Teller < OutputArguments.size(); Teller++)
                    {
                        Map<String,Object> OutputArgument = (Map<String,Object>)OutputArguments[Teller];
                        
                        UpdateRecord.put((String)OutputArgument.get(STRUCTURE_FIELD_NAME), SetFieldValue((String)DataRecord.get((String)OutputArgument.get(STRUCTURE_FIELD_NAME)), (String)OutputArgument.get(STRUCTURE_FIELD_TYPE), (String)OutputArgument.get(STRUCTURE_FIELD_CONVERSION),(String)OutputArgument.get(STRUCTURE_FIELD_CONVERSION_CUSTOM)  ));
                    }
                } 
                Records.add(UpdateRecord);
            }
        }
   
        if (Records.size() > 0)
        {
            try {
                Update Records;
            }
            catch (DMLException e)
            {
                return false;
            }
        }
        
        return true;
    }
    
    //
    // Load all the records for a given Integration Definition
    // 
    public static void LoadObjectData(Map<String,Object> IntegrationStructure)
    {
        Map<String,Object> IntDef;
        
        for (String key : IntegrationStructure.keySet())
        {
            IntDef = (Map<String,Object>)IntegrationStructure.get(key);
            List<String> IDs = (List<String>)IntDef.get(STRUCTURE_IDS);
            if (IDS != null && IDS.size() > 0)
            {
                // There are IDs, so we need to get data.
                List<SObject> Records = Database.query((String)IntDef.get(STRUCTURE_QUERY));
                List<Object> DataRecords = (List<Object>) JSON.deserializeUntyped(JSON.serialize(Records));
                IntDef.put(STRUCTURE_DATA, DataRecords);
            }
        }
    }
    
    // 
    // Add an ID to the Integration Definition linked to Method
    // 
    public static void SetIds(Map<String,Object> IntDef, String Method, String Id)
    {
        List<String> Methods = new List<String> { Method};
        List<STring> IDs = new List<String>{ Id};
        SetIds(IntDef, Methods, IDs);
    }
    
    // Add a list of IDs to Integration Definitions of certain Methods
    // 
    public static void SetIds(Map<String,Object> IntDefs, List<String> MethodList, List<String> IdList)
    {
        for (Integer i=0; i < MethodList.size(); i++)
        {
            Map<String,Object> IntDef = (Map<String,Object>)IntDefs.get(MethodList[i]);
            List<String> IDs = (List<String>)IntDef.get(STRUCTURE_IDS);
            if (IDs == null)
                IDs = new List<String>();
            IDs.add(IdList[i]);
            IntDef.put(STRUCTURE_IDS, IDs);
        }
    }
    
    //
    // Load the integration definition for a given Method
    // 
    public static Map<String,Object> LoadIntegrationStructure(String Method)
    {
        List<String> Methods = new List<String> { Method };
        return LoadIntegrationStructure(Methods);
    }
    
    // Load the integration definition for a list of Methods
    // 
    public static Map<String,Object> LoadIntegrationStructure(List<String> Methods)
    {
         List<Integration_Definition__c> IDs = [select Id, Name, Synchronous__c, HTTP_Method__c, 
                                                Version__c, URL_Method__c, Integration_User__c, Use_Mock_Class__c,
                                                Mock_Class_Name__c, External_Object__c,
                                                Collection_Name__c, Object__c, Integration_Target__r.Name, 
                                                Integration_Target__r.Integration_User__c, 
                                                Integration_Target__r.Named_Credentials__c, 
                                                Integration_Target__r.User_Field_Name__c, 
                                                Integration_Target__r.Namespace__c, 
                                                (select Name, Field_Name__c, Field_Type__c, Field_Conversion__c, Field_Conversion_Custom__c, Fixed__c, Fixed_Value__c, 
                                                 Type__c from Integration_Inputs__r order by Sequence__c), (
                                                 select Name, Field_Name__c, Header_Variable__c, Field_Type__c, Field_Conversion__c, Field_Conversion_Custom__c, External_Id__c  
                                                     from Integration_Outputs__r order by Sequence__c) 
                                                from Integration_Definition__c where Name in :Methods];
        if (!IDs.isEmpty())
        {
            System.Debug('Integration Defs found');
            Map<String, Object> returnStructure = new Map<String,Object>();
        
            for (Integration_Definition__c ID : IDs)
            {
                Map<String,Object> IntDef = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(ID));
                System.Debug(ID.Name + ': ' + JSON.serialize(IntDef));
                IntDef.put(STRUCTURE_IDS, null);
                CreateObjectQuery(IntDef);
            	SetupExternalId(IntDef);
                returnStructure.put(ID.Name, IntDef);  
            }
        
            return returnStructure;
        }
        else
        {
            System.Debug('No Integration defs found');
            return null;
        }
    }
    
    
    //
    //
    private static void SetupExternalId(Map<String,Object> IntDef)
    {
    	if ((Boolean)IntDef.get(STRUCTURE_EXTERNAL_OBJECT))
        {
            Map<String,Object> InputStructure = (Map<String,Object>)IntDef.get(STRUCTURE_INPUTS);
            Map<String,Object> OutputStructure = (Map<String,Object>)IntDef.get(STRUCTURE_OUTPUTS);
            if (Integer.valueOf(OutputStructure.get(STRUCTURE_TOTALSIZE)) > 0)
            {
                List<Object> Outputs = (List<Object>)OutputStructure.get(STRUCTURE_RECORDS);
                List<Object> Inputs;
                if (Integer.valueOf(InputStructure.get(STRUCTURE_TOTALSIZE)) > 0)
                    Inputs = (List<Object>)InputStructure.get(STRUCTURE_RECORDS);
                else
                    Inputs = new List<Object>();
                
                for (Integer j=0; j < Outputs.size(); j++)
                {
                    Map<String,Object> OutputArgument = (Map<String,Object>) Outputs.get(j);
                    if ((Boolean)OutputArgument.get(STRUCTURE_EXTERNAL_ID))
                    {
                        Map<String,Object> InputArgument = new Map<String,Object>(OutputArgument);
                        InputArgument.put(STRUCTURE_NAME, 'ExternalId');
                        InputArgument.put(STRUCTURE_FIELD_NAME, 'ExternalId');
                        InputArgument.put(STRUCTURE_FIXED, false);
                        InputArgument.put(STRUCTURE_TYPE, ARGUMENT_TYPE_URI);
                        Inputs.add(InputArgument);
                    }
                }
                InputStructure.put(STRUCTURE_RECORDS, Inputs);
            }
        }
    }
    //
    // Create the database query for an Integration definition
    // 
    private static void CreateObjectQuery(Map<String,Object> IntDef)
    {
        Map<String,Object> Inputs = (Map<String,Object>)IntDef.get(STRUCTURE_INPUTS);
        String Query = 'select ';
        
        
        if (Integer.valueOf(Inputs.get(STRUCTURE_TOTALSIZE)) > 0)
        {
            //List<Map<String,Object>> Records = (List<Map<String,Object>>)Inputs.get(STRUCTURE_RECORDS);
            List<Object> Records = (List<Object>)Inputs.Get(STRUCTURE_RECORDS);
            
            Integer FieldCount = 0;
            for (Integer i = 0; i < Records.size(); i++ )
            {
                Map<String, Object> InputArgument = (Map<String,Object>)Records.get(i);
                
                if (InputArgument.get(STRUCTURE_FIXED) == false)
                {
                    if (InputArgument.get(STRUCTURE_FIELD_NAME) != null)
                    {
                       if ((FieldCount > 0) && (Query.indexOf((String)InputArgument.get(STRUCTURE_FIELD_NAME)) == -1))
                           Query += ',';
                    
                       if (Query.indexOf((String)InputArgument.get(STRUCTURE_FIELD_NAME)) == -1)
                       {    
                          FieldCount++;
                          Query += InputArgument.get(STRUCTURE_FIELD_NAME);
                       }
                    }
                }
            }
            Query += ' from ';
            Query += IntDef.get(STRUCTURE_OBJECT);
            Query += ' where ID in (';
            System.debug(Query);
            IntDef.put(STRUCTURE_QUERY, Query);     
        }
    }
    
    //
    // Complete the Queries with the IDs to search for
    // 
    public static void FinalizeObjectQueries(Map<String, Object> IntegrationStucture)
    {
        for (String key : IntegrationStucture.keyset())
        {
            Map<String,Object> IntDef = (Map<String,Object>)IntegrationStucture.get(key);
            
            String Query = (String)IntDef.get(STRUCTURE_QUERY);
            List<String> IDs = (List<String>)IntDef.get(STRUCTURE_IDS);
            for (Integer i = 0; i < IDs.size(); i++)
            {
                if (i > 0)
                    Query += ',';
                Query += '\'';
                Query += IDs[i];
                Query += '\'';
            }
            Query += ')';
            IntDef.put(STRUCTURE_QUERY, Query);
        }
    }
    
    
    //
    // Converts Salesforce values to REST values
    // 
    public static String GetFieldValue(Object FieldValue, String FieldType, String FieldConversion, String CustomFieldConversion)
    {
        System.Debug('GetFieldValue: ' + FieldValue + ', ' + FieldType + ', ' + FieldConversion);
        
        if (FieldValue == null)
            return '';
        
        if (FieldConversion == FIELD_CONVERSION_CUSTOM)
        {
            RESTDataConversion TheConversion;
        	Type conversionType = Type.forName(CustomFieldConversion);
        	if (null != conversionType)
        	{
        		TheConversion = (RESTDataConversion) conversionType.newInstance();
        	    return String.valueOf(TheConversion.SalesforceToExternalFormat(FieldValue));
        	}
            else
                return null;
        }
        else
        {
            if (FieldType == FIELD_TYPE_BOOLEAN)
            {
                if (FieldConversion == FIELD_CONVERSION_BOOLEAN_Y_N)
                {
                	if (FieldValue == true)
                    	return FIELD_TYPE_BOOLEAN_TRUE;
                	else
                    	return FIELD_TYPE_BOOLEAN_FALSE;
                }
                else if (FieldConversion == FIELD_CONVERSION_BOOLEAN_TRUE_FALSE)
                {
                    return String.valueOf(FieldValue);
                }
                else
                    return String.valueOf(FieldValue);
            }    
            else if (FieldType == FIELD_TYPE_DATE)
            {
                if (FieldConversion == FIELD_CONVERSION_DATE_JULIAN)
                {
                    RESTDateJulianConversion JulianDate = new RESTDateJulianConversion();
                    return String.valueOf(JulianDate.SalesforceToExternalFormat(FieldValue));
                }
                else if (FieldConversion == FIELD_CONVERSION_DATE_DDMMYYYY)
                {
                    RESTDateDDMMYYYYConversion DateConversion = new RESTDateDDMMYYYYConversion();
                    return String.valueOf(DateConversion.SalesforceToExternalFormat(FieldValue));
                }
                else if (FieldConversion == FIELD_CONVERSION_DATE_MMDDYYYY)
                {
                    RESTDateMMDDYYYYConversion DateConversion = new RESTDateMMDDYYYYConversion();
                    return String.valueOf(DateConversion.SalesforceToExternalFormat(FieldValue));
                }
                else
                    return ((DateTime)FieldValue).format('yyyy-mm-dd') + 'T' + ((DateTime)FieldValue).format('HH:mm:ss.SSS') + 'Z';
            }
            else
                return String.valueOf(FieldValue);
        }
    }

    //
    // Converts the REST values to Salesforce values
    // 
    public static Object SetFieldValue(String FieldValue, String FieldType, String FieldConversion, String CustomFieldConversion)
    {
        if (FieldConversion == 'Custom')
        {
            RESTDataConversion TheConversion;
        	Type conversionType = Type.forName(CustomFieldConversion);
        	if (null != conversionType)
        	{
        		TheConversion = (RESTDataConversion) conversionType.newInstance();
        	    return TheConversion.ExternalFormatToSalesForce(FieldValue);
        	}
            else
                return null;
        }
        else
        {
            if (FieldType == FIELD_TYPE_BOOLEAN)
            {
                if (FieldConversion == FIELD_CONVERSION_BOOLEAN_Y_N)
                {
                    if (FieldValue == FIELD_TYPE_BOOLEAN_TRUE)
                        return true;
                    else
                        return false;
                }
                else if (FieldConversion == FIELD_CONVERSION_BOOLEAN_TRUE_FALSE)
                {
                    return FieldValue;
                }
                else 
                    return false;
            }
            else if (FieldType == FIELD_TYPE_NUMBER)
                return integer.valueOf(FieldValue);
            else if (FieldType == FIELD_TYPE_DATE)
            {
                if (FieldConversion == FIELD_CONVERSION_DATE_JULIAN)
                {
                    RESTDateJulianConversion JulianDate = new RESTDateJulianConversion();
                    return JulianDate.ExternalFormatToSalesForce(FieldValue);
                 }
                else if (FieldConversion == FIELD_CONVERSION_DATE_DDMMYYYY)
                {
                    RESTDateDDMMYYYYConversion DateConversion = new RESTDateDDMMYYYYConversion();
                    return DateConversion.ExternalFormatToSalesforce(FieldValue);
                }
                else if (FieldConversion == FIELD_CONVERSION_DATE_MMDDYYYY)
                {
                    RESTDateMMDDYYYYConversion DateConversion = new RESTDateMMDDYYYYConversion();
                    return DateConversion.ExternalFormatToSalesforce(FieldValue);
                }
                else
                {
                    // 20161206T100929.831 GMT
                    String sDate = (String)FieldValue;
                    String Year = sDate.substring(0,4);
                    String Month = sDate.substring(4,6);
                    String Day = sDate.substring(6,8);
                    String Hour = sDate.substring(9,11);
                    String Minute = sDate.substring(11,13);
                    String Secs = sDate.substring(13,15);
                    
                    sDate = Year + '-' + Month + '-' + Day + ' ' + Hour + ':' + Minute + ':' + Secs;
                    return Date.valueOf(sDate);
                }
               
            }
            else
                return FieldValue;
        }
    }
  
	
}