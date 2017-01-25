global class RESTDataSourceConnection extends DataSource.Connection {
    
   
    /**
     *   Constructors.
     **/
    global RESTDataSourceConnection(DataSource.ConnectionParams connectionParams) {
    }
    
    global RESTDataSourceConnection() {
    }
    
        /**
     *   Called when an external object needs to get a list of 
     *   schema from the external data source, for example when 
     *   the administrator clicks “Validate and Sync” in the 
     *   user interface for the external data source.   
     **/
   
        override global List<DataSource.Table> sync() {
        List<Integration_Definition__c> PCs = [Select Id, Name, URL_Method__c, Object__c from Integration_Definition__c where External_Object__c = true];
        List<DataSource.Table> tables = new List<DataSource.Table>();        
        
        for (Integration_Definition__c PC : PCs)
        {
            List<DataSource.Column> columns = new List<DataSource.Column>();
            
            columns.add(DataSource.Column.text('ExternalId', 255));
            columns.add(DataSource.Column.url('DisplayUrl'));
            
            List<Integration_Input__c> IntegrationInputs = [select Id, Name, Field_Name__c, Fixed__c, Fixed_Value__c from Integration_Input__c where Integration_Definition__c = :PC.Id order by sequence__c];
                
            for (Integration_Input__c II : IntegrationInputs)
            {
                columns.add(DataSource.Column.text(II.Name, 255));    
            }
            
            List<Integration_Output__c> PegaOutputs = [select Name, Field_Name__c, Field_Type__c from Integration_Output__c where Integration_Definition__c = :PC.Id order by sequence__c];
                   
            for (Integration_Output__c PO : PegaOutputs)
            {
                Boolean bFound = false;
                
                for (DataSource.Column c : columns)
                {
                    if (c.name == PO.Name)
                        bFound = true;
                }
                
                if (!bFound)
                {
                    if (PO.Field_Type__c == 'Text')
                        columns.add(DataSource.Column.text(PO.Name, 255));
                    else if (PO.Field_Type__c == 'Url')
                        columns.add(DataSource.Column.url(PO.Name));
                    else if (PO.Field_Type__c == 'Number')
                        columns.add(DataSource.Column.number(PO.Name,18,0));
                    else if (PO.Field_Type__c == 'Date')
                        columns.add(DataSource.Column.get(PO.Name, PO.Name, PO.Name, true, true, DataSource.DataType.DATETIME_TYPE, 18 ));
                    else if (PO.FIeld_Type__c == 'Boolean')
                        columns.add(Datasource.Column.boolean(PO.Name));
                }
            }
        
            tables.add(
                DataSource.Table.get(PC.Name, 'Name', columns));
        }
        return tables;
    }
    
    
    /**
     *   Called to query and get results from the external 
     *   system for SOQL queries, list views, and detail pages 
     *   for an external object that’s associated with the 
     *   external data source.
     *   
     *   The QueryContext argument represents the query to run 
     *   against a table in the external system.
     *   
     *   Returns a list of rows as the query results.
     **/
    override global DataSource.TableResult query(DataSource.QueryContext context) {
             
        System.Debug('JVD Pega Query');
        List<Map<String,Object>> rows = execQuery(context);
            
        return DataSource.TableResult.get(context,rows);     
    }
    
    /**
     *   Called to do a full text search and get results from
     *   the external system for SOSL queries and Salesforce
     *   global searches.
     *   
     *   The SearchContext argument represents the query to run 
     *   against a table in the external system.
     *   
     *   Returns results for each table that the SearchContext 
     *   requested to be searched.
     **/
    override global List<DataSource.TableResult> search(DataSource.SearchContext context) {        
        System.Debug('JVD Pega Search By Name');
        return DataSource.SearchUtils.searchByName(context, this);
    }
  
    
     private List<Map<String,Object>> execQuery(DataSource.QueryContext context) {
            
         List<Map<String,Object>> rows = new List<Map<String,Object>>();
       
         System.Debug('JVD PegaDataSourceConnection.execQuery');
         System.Debug('JVD Table requested: ' + context.tableSelection.tableSelected);
         System.Debug('JVD Filter' + context.tableSelection.filter);
            
         Map<String,Object> outboundContentMap = new Map<String,Object>();
              
         if (context.tableSelection.filter != null)
         {
             Integration_Definition__c ID = [select Id, Name, URL_Method__c, Object__c, Integration_User__c, Collection_Name__c, Integration_Target__r.Name, Integration_Target__r.Integration_User__c, Integration_Target__r.Named_Credentials__c, Integration_Target__r.User_Field_Name__c  from Integration_Definition__c where Name = :context.tableSelection.tableSelected];
             
             if (ID != null)
             {
                 String userIdentifier = UserInfo.getUserName();
                 if (ID.Integration_User__c)
                     userIdentifier = ID.Integration_Target__r.Integration_User__c;
                 
                 List<Integration_Input__c> IIs = [select Id, Name, Type__c from Integration_Input__c where Integration_Definition__c = :ID.Id  order by Sequence__c];
                 
                 String URI = 'callout:' + ID.Integration_Target__r.Named_Credentials__c + '/'  + ID.URL_Method__c;
                 
                 String RecordIdentifierName = '';
                 String RecordIdentifierValue = '';
                 String QueryParameters = '';
               
       
                 for (Integration_Input__c II : IIs)
                 {
                     System.Debug('Searching for ' + II.Name);
                     if (context.tableSelection.filter.columnName == II.Name)
                     {
                         if (II.Type__c == 'Query Parameter')
                            QueryParameters += '&' + II.Name + '=' + EncodingUtil.urlEncode((String)context.tableSelection.filter.columnValue,'UTF-8');
                         else if (II.Type__c == 'URI')
                             URI += '/' + EncodingUtil.urlEncode((String)context.tableSelection.filter.columnValue,'UTF-8');
                           
                         RecordIdentifierName = II.Name;
                         RecordIdentifierValue = (String)context.tableSelection.filter.columnValue;
                     }
                     
                     List<DataSource.Filter> SubFilters = context.tableSelection.filter.subfilters;
                     
                     
                     
                     if (SubFilters != null && !SubFilters.isEmpty())
                     {
                         for (DataSource.Filter f : SubFilters)
                         {
                             
                             if (f.columnName == II.Name)
                             {
                                 SYstem.Debug('Type: ' + II.Type__c);
                                 if (II.Type__c == 'Query Parameter')
                                     QueryParameters += '&' + II.Name + '=' + EncodingUtil.urlEncode((String)f.columnValue,'UTF-8');
                                 else if (II.Type__c == 'URI')
                                     URI += '/' + EncodingUtil.urlEncode((String)f.columnValue,'UTF-8');
                                 RecordIdentifierName = II.Name;
                                 RecordIdentifierValue = (string)f.columnValue;
                             }
                         }
                     }
                 }
                 if (ID.Integration_Target__r.User_Field_Name__c != null && QueryParameters.length() > 0)
                     URI += '?' + ID.Integration_Target__r.User_Field_Name__c + '=' + userIdentifier + QueryParameters;
                 else if (QueryParameters.length() > 0)
                 {
                     URI += '?' + QueryParameters.substring(1);
                 }
                 
                 System.debug('URI: ' + URI);
                 
                 if (RecordIdentifierName != '')
                 {
                     System.Debug('URI: ' + URI);
                     System.Debug(RecordIdentifierName + ': ' + RecordIdentifierValue);
                     String outboundContentJson = Json.serialize(outboundContentMap);
                     HttpRequest req = new HttpRequest();
                   
                     req.setEndpoint(URI);
                     System.debug('EndPoint: ' + req.getEndpoint());
                     //req.setBody(outboundContentJson);
                     req.setMethod('GET');
                     Http http = new Http();
                     HTTPResponse res = http.send(req);
                     
                     System.debug('Statuscode: ' + res.getStatusCode());
                        
                     // Test to see if the call was succesfull 
                     if (res.getStatusCode() == 200 || res.getStatusCode() == 201)
                     {
                         System.debug('Call was succesful');
                         System.debug('Return JSON: ' + res.getBody());
                         System.debug('Body size: ' + res.getBody().length() );
                         
                          /*Write Log
                            Integration_Log__c IL = new Integration_Log__c();
                            
                            IL.Name = context.tableSelection.tableSelected;
                            IL.Integration_Id__c = RecordIdentifierValue;
                            IL.Output_Message__c = res.getBody();
                            IL.Status_Code__c = res.getStatusCode();
                            Insert IL;*/
        
                         List<Object> Children;
                      
                         if (ID.Collection_Name__c == null || ID.Collection_Name__c == '')
                         {
                             System.Debug('Empty collection name');
                              Children = (List<Object>)Json.deserializeUntyped(res.getBody());
                             
                         }
                         else
                         {
                             Map<String, Object> resultBody = (Map<String, Object>)Json.deserializeUntyped(res.getBody());
                    
                             if (ID.Collection_Name__c.indexOf('.') > 0)
                             {
                                 System.Debug('Geneste collection;');
                                 String[] Collections = ID.Collection_Name__c.Split('\\.');
                                 
                                 if (resultBody.containsKey(Collections[0]))
                                 {
                                     System.Debug('toplevel gevonden');
                                     Map<String, Object> Temp = (Map<String,Object>)resultBody.get(Collections[0]);
                                           
                                     for (Integer j = 1; j < Collections.size(); j++)
                                     {
                                         System.Debug('Level ' + j + ', ' + Collections[j]);
                                         if (j < Collections.size() -1)
                                         {
                                            Temp = (Map<String,Object>)resultBody.get(Collections[0]);
                                         }
                                         else
                                         {
                                             Children = (List<Object>)Temp.get(Collections[j]);
                                         }
                                         
                                     }
                                 }
                             }
                             else if (resultBody.containsKey(ID.Collection_Name__c))
                             {    
                                 System.Debug('Collection name: ' + ID.Collection_Name__c);
                                 Children = (List<Object>)resultBody.get(ID.Collection_Name__c);
                              }
                         }
                         
                         if (Children != null && !Children.isEmpty())
                         {
                             System.debug('There are children');
                             System.debug(Children);
                             List<Integration_Output__c> IOs = [select Name, External_Id__c, Field_Type__c from Integration_Output__c where Integration_Definition__c = :ID.Id];
                             
                             for (Object child : Children)
                             {
                                 Map<String, Object> childMap = (Map<String,Object>)child;
                                 
                                 Map<String, Object> row = new Map<String, Object>();
                                 
                                 row.put('DisplayUrl','');
                                 
                                 for (Integration_Output__c IO : IOs)
                                 {
                                     if (IO.Name.indexOf('.') != -1)
                                     {
                                         String[] FieldInfo = IO.Name.Split('\\.');
                                         Map<String,Object> grandchild = (Map<String,Object>)childMap.get(FieldInfo[0]);
                                         
                                         SetFieldValue(row, IO.Name, grandchild.get(FieldInfo[1]), IO.Field_Type__c);
                                        
                                         if (IO.External_Id__c)
                                         {
                                             row.put('ExternalId', grandchild.get(FieldInfo[1]));
                                             System.debug('External Id: (' + IO.Name + ')' + row.get('ExternalId'));
                                         }
                                     }
                                     else 
                                     {
                                        SetFieldValue(row, IO.Name, childMap.get(IO.Name), IO.Field_Type__c);
                                         
                                         if (IO.External_Id__c)
                                         {
                                             row.put('ExternalId', childMap.get(IO.Name));
                                             System.debug('External Id: (' + IO.Name + ')' + row.get('ExternalId'));
                                         }
                                     }
                                     
                                     
                                 }
                                 System.Debug(RecordIdentifierName + ': ' + RecordIdentifierValue);
                                 row.put(RecordIdentifierName, RecordIdentifierValue);
                                 rows.add(row);
                                 
                             }
                         }
                      }
                 }
                 
                 
             }
         }
         return rows;
     }
    
    
    private void SetFieldValue(Map<String, Object> row, String FieldName, Object FieldValue, String FieldType)
    {
        if (FieldType == 'Text')
            row.put(FieldName, FieldValue);
        else if (FieldType == 'Url')
            row.put(FieldName, FieldValue);
        else if (FieldType == 'Number')
            row.put(FieldName, integer.valueOf(FieldValue));
        else if (FieldType == 'Date')
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
            row.put(FieldName, Date.valueOf(sDate));
        }
        else if (FIeldType == 'Boolean')
        {
            if (FieldValue == 'true')
                row.put(FieldName, true);
            else
                row.put(FieldName, false);
        }
    }
}