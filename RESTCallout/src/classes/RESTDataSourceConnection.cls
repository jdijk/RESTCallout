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
             
        System.Debug('JVD Query');
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
        System.Debug('JVD Search By Name');
        return DataSource.SearchUtils.searchByName(context, this);
    }
  
    
     private List<Map<String,Object>> execQuery(DataSource.QueryContext context) {
            
         List<Map<String,Object>> rows = new List<Map<String,Object>>();
       
         
         System.Debug('JVD RESTDataSourceConnection.execQuery');
         System.Debug('JVD Table requested: ' + context.tableSelection.tableSelected);
         System.Debug('JVD Filter' + context.tableSelection.filter);
         String RecordIdentifierName;
         String RecordIdentifierValue;
          
         Map<String,Object> outboundContentMap = new Map<String,Object>();
              
         if (context.tableSelection.filter != null)
         {
         	Map<String,Object> IntStruct = RESTCallout.LoadIntegrationStructure(context.tableSelection.tableSelected);
            System.Debug('After def load');
         	System.Debug(JSON.serialize(IntStruct));
         	Map<String,Object> IntDef = (Map<String,Object>)IntStruct.get(context.tableSelection.tableSelected);
         	
         	System.Debug(JSON.serialize(IntDef));
         	Map<String,Object> DataObject = new Map<String,Object>();
         	HttpRequest req = new HttpRequest();
         	
            if (context.tableSelection.filter.columnName != null)
            {
         		DataObject.put(context.tableSelection.filter.columnName,context.tableSelection.filter.columnValue );
         		RecordIdentifierName = context.tableSelection.filter.columnName;
            	RecordIdentifierValue = (String)context.tableSelection.filter.columnValue;
            }
             
         	List<DataSource.Filter> SubFilters = context.tableSelection.filter.subfilters;
         	
         	if (SubFilters != null && !SubFilters.isEmpty())
         	{
         		for (DataSource.Filter f : SubFilters)
                {
                	DataObject.put(f.columnName, f.columnValue);
                	RecordIdentifierName = f.columnName;
                    RecordIdentifierValue = (String)f.columnValue;
                }
         	}
         	System.Debug(DataObject);
             
         	RESTCallout.PrepareInput(IntDef, DataObject, req);
 
 			if (RecordIdentifierName != '')
 			{
            	req.setMethod('GET');
                HTTPResponse res;
        
                // Decide if we do a real call or call a mock class.
                if ((Boolean)IntDef.get(RESTCallOut.STRUCTURE_USE_MOCK))
                {
                    RESTMockService TheMock;
                    Type mockType = Type.forName((String)IntDef.get(RESTCallOut.STRUCTURE_MOCK_CLASS));
                    if (null != mockType)
                    {
                        TheMock = (RESTMockService) mockType.newInstance();
                        res = TheMock.GetMockResponse(IntDef, DataObject);
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
                        
                // Test to see if the call was succesfull 
                if (res.getStatusCode() == 200 || res.getStatusCode() == 201)
                {
                     System.debug('Call was succesful');
                     System.debug('Return JSON: ' + res.getBody());
                     System.debug('Body size: ' + res.getBody().length() );
                     
                     List<Object> Children;
                  	 Map<String,Object> SingleChild;
                    
                     if (IntDef.get(RESTCallout.STRUCTURE_COLLECTION) == null || IntDef.get(RESTCallout.STRUCTURE_COLLECTION) == '')
                     {
                         System.Debug('Empty collection name');
                         if (res.getBody().trim().indexOf('[') == 0)
                          	Children = (List<Object>)Json.deserializeUntyped(res.getBody());
                         else
                         {
                             SingleChild = (Map<String,Object>)Json.deserializeUntyped(res.getBody());
                             Children = new List<Object>{ SingleChild };
                         }
                         
                     }
                     else
                     {
                         Map<String, Object> resultBody = (Map<String, Object>)Json.deserializeUntyped(res.getBody());
                
                         if (((String)IntDef.get(RESTCallout.STRUCTURE_COLLECTION)).indexOf('.') > 0)
                         {
                             System.Debug('Geneste collection;');
                             String[] Collections = ((String)IntDef.get(RESTCallout.STRUCTURE_COLLECTION)).Split('\\.');
                             
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
                                         if (JSON.serialize(Temp.get(Collections[j])).trim().indexOf('[') == 0)
                                         	Children = (List<Object>)Temp.get(Collections[j]);
                                         else
                                         {
                                             SingleChild = (Map<String,Object>)Temp.get(Collections[j]);
                                             Children = new List<Object>{SingleChild};
                                         }
                                     }
                                     
                                 }
                             }
                         }
                         else if (resultBody.containsKey((String)IntDef.get(RESTCallout.STRUCTURE_COLLECTION)))
                         {    
                             System.Debug('Collection name: ' + IntDef.get(RESTCallout.STRUCTURE_COLLECTION));
                             if (JSON.serialize(resultBody.get((String)IntDef.get(RESTCallout.STRUCTURE_COLLECTION))).trim().indexOf('[') == 0)
                             	Children = (List<Object>)resultBody.get((String)IntDef.get(RESTCallout.STRUCTURE_COLLECTION));
                             else
                             {
                                 SingleChild = (Map<String,Object>)resultBody.get((String)IntDef.get(RESTCallout.STRUCTURE_COLLECTION));
                                 Children = new List<Object>{SingleChild};
                             }
                          }
                     }
                     
                     if (Children != null && !Children.isEmpty())
                     {
                         System.debug('There are children');
                         System.debug(Children);
                          
                         for (Object child : Children)
                         {
                             Map<String, Object> childMap = (Map<String,Object>)child;
                             
                             Map<String, Object> row = new Map<String, Object>();
                             
                             row.put('DisplayUrl','');
                             Map<String, Object> OutputArguments = (Map<String,Object>)IntDef.get(RESTCallout.STRUCTURE_OUTPUTS);
                            List<Object> records = (List<Object>)OutputArguments.get(RESTCallout.STRUCTURE_RECORDS);
                             
                             for (Integer J = 0; J < records.size(); J++)
                             {
                             	Map<String,Object> record = (Map<String,Object>)records[J];
                             	
                                 if (((String)record.get(RESTCallout.STRUCTURE_NAME)).indexOf('.') != -1)
                                 {
                                     String[] FieldInfo = ((String)record.get(RESTCallout.STRUCTURE_NAME)).Split('\\.');
                                     Map<String,Object> grandchild = (Map<String,Object>)childMap.get(FieldInfo[0]);
                                     
                                     SetFieldValue(row, ((String)record.get(RESTCallout.STRUCTURE_NAME)), grandchild.get(FieldInfo[1]), (String)record.get(RESTCallout.STRUCTURE_FIELD_TYPE));
                                    
                                     if ((Boolean)record.get(RESTCallout.STRUCTURE_EXTERNAL_ID))
                                     {
                                         row.put('ExternalId', grandchild.get(FieldInfo[1]));
                                         System.debug('External Id: (' + ((String)record.get(RESTCallout.STRUCTURE_NAME)) + ')' + row.get('ExternalId'));
                                     }
                                 }
                                 else 
                                 {
                                    SetFieldValue(row, ((String)record.get(RESTCallout.STRUCTURE_NAME)), childMap.get(((String)record.get(RESTCallout.STRUCTURE_NAME))), (String)record.get(RESTCallout.STRUCTURE_FIELD_TYPE));
                                     
                                     if ((Boolean)record.get(RESTCallout.STRUCTURE_EXTERNAL_ID))
                                     {
                                         row.put('ExternalId', childMap.get(((String)record.get(RESTCallout.STRUCTURE_NAME))));
                                         System.debug('External Id: (' + ((String)record.get(RESTCallout.STRUCTURE_NAME)) + ')' + row.get('ExternalId'));
                                     }
                                 }
                                 
                                 
                             }
                             System.Debug(RecordIdentifierName + ': ' + RecordIdentifierValue);
                             row.put(RecordIdentifierName, RecordIdentifierValue);
                             System.Debug(row);
                             rows.add(row);
                             
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