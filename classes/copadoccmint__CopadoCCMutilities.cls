/**
 * Utilities class for CCM Integrations.
 *
 * @author Ümit Can Uçkan
 * @lastModifiedBy : Kunal Kaushik
 * @version 1.0
 * @since CCM Integrations 1.0
 */
global with sharing class CopadoCCMutilities {
    
    @InvocableMethod(Label='Clone project with child records' Description='Clone project with child records' category='Integration Project creation')
    global static List<String> cloneProjectWithChildRecords(List<Id> proIds) {
        copado__project__c project = [SELECT Id, Name, copado__Deployment_Flow__c, copado__Description__c, copado__End_Date__c, copado__Start_Date__c, copado__Status__c, copado__Index_Metadata__c, copado__Exclude_Tabs_from_Promotion_Page__c, copadoccmint__Copado_Integration_Setting__c, copadoccmint__Enable_Community_User__c, copadoccmint__Enable_Logs__c, copadoccmint__JQL_Extended_Filter__c, copadoccmint__Project_External_Id__c, copadoccmint__Sprint_Per_Batch_Chunk_Size__c, copadoccmint__Team_Info__c, copadoccmint__Workspace_Id__c,
            (SELECT Id, copadoccmint__Project__c, copadoccmint__SF_Theme_Name__c, copadoccmint__TP_Theme_Name__c FROM copadoccmint__Theme_Mappings__r), 
            (SELECT Id, copadoccmint__Project__c, copadoccmint__Salesforce_Record_Type_Name__c, copadoccmint__Third_Party_Record_Type_Name__c FROM copadoccmint__Record_Type_Mappings__r),
            (SELECT Id, copadoccmint__Exclude_from_su__c, copadoccmint__Exclude_from_tpu__c, copadoccmint__Project__c, copadoccmint__Salesforce_Field_Name__c, copadoccmint__Target_Field_Type__c, copadoccmint__Third_Party_Field_Name__c FROM copadoccmint__Field_Mappings__r) FROM copado__Project__c WHERE Id IN : proIds WITH USER_MODE];
        
        copado__project__c clonedProject = project.clone(false, false, false, false);
        clonedProject.Name = clonedProject.Name + ' (cloned project)';
        insert clonedProject;    
        
        List<copadoccmint__Theme_Mapping__c> themeMappings = new List<copadoccmint__Theme_Mapping__c>();
        for(copadoccmint__Theme_Mapping__c theme : project.copadoccmint__Theme_Mappings__r){
            copadoccmint__Theme_Mapping__c newTheme = new copadoccmint__Theme_Mapping__c();
            newTheme.copadoccmint__Project__c = clonedProject.Id;
            newTheme.copadoccmint__SF_Theme_Name__c = theme.copadoccmint__SF_Theme_Name__c;
            newTheme.copadoccmint__TP_Theme_Name__c = theme.copadoccmint__TP_Theme_Name__c;
            themeMappings.add(newTheme);
        }
        insert themeMappings;
        
        List<copadoccmint__Field_Mapping__c> fieldMappings = new List<copadoccmint__Field_Mapping__c>();
        for(copadoccmint__Field_Mapping__c fieldMapping : project.copadoccmint__Field_Mappings__r){
            copadoccmint__Field_Mapping__c newFieldMapping = new copadoccmint__Field_Mapping__c();
            newFieldMapping.copadoccmint__Project__c = clonedProject.Id;
            newFieldMapping.copadoccmint__Exclude_from_su__c = fieldMapping.copadoccmint__Exclude_from_su__c;
            newFieldMapping.copadoccmint__Exclude_from_tpu__c = fieldMapping.copadoccmint__Exclude_from_tpu__c;
            newFieldMapping.copadoccmint__Salesforce_Field_Name__c = fieldMapping.copadoccmint__Salesforce_Field_Name__c;
            newFieldMapping.copadoccmint__Target_Field_Type__c = fieldMapping.copadoccmint__Target_Field_Type__c;
            newFieldMapping.copadoccmint__Third_Party_Field_Name__c = fieldMapping.copadoccmint__Third_Party_Field_Name__c;
            fieldMappings.add(newFieldMapping);
        }
        insert fieldMappings;
        
        List<copadoccmint__Record_Type_Mapping__c> recordTypes = new List<copadoccmint__Record_Type_Mapping__c>();
        for(copadoccmint__Record_Type_Mapping__c recortTypeMapping : project.copadoccmint__Record_Type_Mappings__r){
            copadoccmint__Record_Type_Mapping__c newrecortTypeMapping = new copadoccmint__Record_Type_Mapping__c();
            newrecortTypeMapping.copadoccmint__Project__c = clonedProject.Id;
            newrecortTypeMapping.copadoccmint__Salesforce_Record_Type_Name__c = recortTypeMapping.copadoccmint__Salesforce_Record_Type_Name__c;
            newrecortTypeMapping.copadoccmint__Third_Party_Record_Type_Name__c = recortTypeMapping.copadoccmint__Third_Party_Record_Type_Name__c;
            recordTypes.add(newrecortTypeMapping);
        }
        insert recordTypes;
        return new List<String>{clonedProject.Id};
    }
    //callout log list to be inserted as a final action
    public static List<Callout_Log__c> callOutLogList2Insert {
        get {
            if (callOutLogList2Insert == null) {
                callOutLogList2Insert = new List<Callout_Log__c>();
            }
            return callOutLogList2Insert;
        }
        set;
    }

    /**
     * HTTP method based on a named credential and current parameters
     * Project and UserStory are required parameters for log creation
     *
     * @param namedCredential
     * @param firstParam
     * @param secondParam
     * @param firstUrlpart
     * @param secondUrlpart
     * @param additionalHeader
     * @param methodType
     * @param bodyParam
     * @param userStory
     * @param project
     *
     * @return
     */
    public static String MakeCallout(
        String namedCredential,
        String firstParam,
        String secondParam,
        String firstUrlpart,
        String secondUrlpart,
        List<String> additionalHeader,
        Method methodType,
        String bodyParam,
        sObject userStory,
        sObject project
    ) {
        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);
        //exp: callout: endpoint + projectExternalId + '/_apis/wit/wiql/' + workspaceId +'?api-version=4.1';
        System.debug('endpoint===> ' + 'callout:' + namedCredential + '/' + firstParam + firstUrlpart + secondParam + secondUrlpart);
        req.setEndpoint('callout:' + namedCredential + '/' + firstParam + firstUrlpart + secondParam + secondUrlpart);
        for (String ahItem : additionalHeader) {
            req.setHeader(ahItem.split(':')[0], ahItem.split(':')[1]);
        }
        req.setMethod(String.valueOf(methodType));
        if (String.isNotBlank(bodyParam)) {
            req.setBody(bodyParam);
        }
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (userStory != null && (Boolean) userStory.get('Enable_Logs__c')) {
            callOutLogList2Insert.add(
                new Callout_Log__c(
                    Response_Body__c = res.getBody(),
                    Status__c = res.getStatus(),
                    Status_Code__c = String.valueOf(res.getStatusCode()),
                    User_Story__c = (String) userStory.get('id')
                )
            );
        } else if (null != project && (Boolean) project.get('ENABLE_Logs__c')) {
            callOutLogList2Insert.add(
                new Callout_Log__c(
                    Response_Body__c = res.getBody(),
                    Status__c = res.getStatus(),
                    Status_Code__c = String.valueOf(res.getStatusCode()),
                    project__c = (String) project.get('id')
                )
            );
        }
        System.debug('res.getBody()==> ' + res.getBody());
        return res.getBody();
    }
    //Map to use on dynamic cast logic
    private static Map<String, Schema.SObjectField> userStoryFieldsMap;
    static {
        userStoryFieldsMap = Schema.SObjectType.copado__User_Story__c.fields.getMap();
    }
    //casts value based on the current sObject field
    public static Object returnCastedValue(Object param, String fname) {
        if (null != param) {
            Schema.SObjectField field = userStoryFieldsMap.get(fname);
            String FldType = String.valueOf(field.getDescribe().getType()).toLowerCase();
            if (FldType == 'textarea' || FldType == 'picklist' || fldType == 'reference' || FldType == 'multipicklist') {
                FldType = 'string';
            }
            if (FldType == 'boolean') {
                return Boolean.valueOf(param);
            } else if (FldType == 'string') {
                return String.valueOf(param);
            } else if (FldType == 'blob') {
                return (Blob) param;
            } else if (FldType == 'date') {
                return Date.valueOf(applySalesforceDateFormatString(param));
            } else if (FldType == 'datetime') {
                return Datetime.valueOf(applySalesforceDateTimeFormatString(param));
            } else if (FldType == 'time') {
                return (Time) param;
            } else if (FldType == 'integer') {
                return Integer.valueOf(param);
            } else if (FldType == 'long') {
                return (Long) param;
            } else if (FldType == 'decimal') {
                return (Decimal) param;
            } else if (FldType == 'double') {
                return Double.valueOf(param);
            }
        }
        return null;
    }
    private static String applySalesforceDateFormatString(Object param) {
        return String.valueOf(param).replace('Z', '+0000');
    }
    private static String applySalesforceDateTimeFormatString(Object param) {
        return String.valueOf(param).replace('T', ' ');
    }

    public static Map<String, Id> returnThemeMap() {
        Map<String, Id> themeMap = new Map<String, Id>();
        for (copado__Theme__c theme : [SELECT Id, Name FROM copado__Theme__c]){
            themeMap.put(theme.Name.toLowerCase(), theme.Id);
        }
        return themeMap;
    }
    public static Map<String, Id> returnTeamMap() {
        Map<String, Id> teamMap = new Map<String, Id>();
        for (copado__Team__c team : [SELECT Id, Name FROM copado__Team__c]){
            teamMap.put(team.Name.toLowerCase(), team.Id);
        }
        return teamMap;
    }

    public static Map<String, String> returnThemeMappingForProject(Id projectId){
        Map<String, String> themeMapping = new Map<String, String>();
        for(Theme_Mapping__c tm : [SELECT SF_Theme_Name__c, TP_Theme_Name__c FROM Theme_Mapping__c WHERE Project__c = : projectId]){
            themeMapping.put(tm.TP_Theme_Name__c.toLowerCase(), tm.SF_Theme_Name__c.toLowerCase());
        }
        return themeMapping;
    }

    //Field mapping values between salesforce and third party platform fields under related project
    public static Map<String, String> returnFieldMap(id pid, String additionalWhereClause) {
        Map<String, String> fieldMap;
        if (null == fieldMap) {
            fieldMap = new Map<String, String>();
            for (
                Field_Mapping__c fm : database.query(
                    'SELECT Salesforce_Field_Name__c, Third_Party_Field_Name__c FROM Field_Mapping__c WHERE project__c =: pid ' +
                    CommonIntegrationConstants.MAP_ADDITIONAL_WHERE.get(additionalWhereClause)
                )
            ) {
                fieldMap.put(fm.Salesforce_Field_Name__c.toLowerCase(), fm.Third_Party_Field_Name__c.toLowerCase());
            }
        }
        return fieldMap;
    }

    //returns Name/DeveloperName to Id map of User Story object's recordTypes
    public static Map<String, String> returnUserStoryRecordTypeMap(Boolean forJIRA) {
        Map<String, String> userStoryRecordTypes = new Map<String, String>();
        for (RecordType recordType : [
            SELECT Id, Name, DeveloperName
            FROM RecordType
            WHERE IsActive = TRUE AND SobjectType = 'copado__User_Story__c'
        ]) {
            if (!forJIRA) {
                userStoryRecordTypes.put(recordType.DeveloperName, recordType.Id);
                userStoryRecordTypes.put(recordType.Name, recordType.Id);
            } else {
                userStoryRecordTypes.put(recordType.Id, recordType.Name);
            }
        }
        return userStoryRecordTypes;
    }

    //Record Type mapping values between salesforce and third party platform work Items under related project
    public static Map<String, String> returnRecordTypeMap(Id pid, Boolean forThirdParty) {
        Map<String, String> recordTypeMap;
        if (null == recordTypeMap) {
            recordTypeMap = new Map<String, String>();
            for (
                Record_Type_Mapping__c recordType : database.query(
                    'SELECT Salesforce_Record_Type_Name__c, Third_Party_Record_Type_Name__c FROM Record_Type_Mapping__c WHERE project__c =: pid '
                )
            ) {
                if (!forThirdParty) {
                    recordTypeMap.put(recordType.Third_Party_Record_Type_Name__c, recordType.Salesforce_Record_Type_Name__c);
                } else {
                    recordTypeMap.put(recordType.Salesforce_Record_Type_Name__c, recordType.Third_Party_Record_Type_Name__c);
                }
            }
        }
        return recordTypeMap;
    }
    //returns a map with sf field api name to target field type, (if the target field on the third party program expect String or a json Object as a value **** defined by "target field type" field on the field mapping Object ****)
    public static Map<String, String> returnTargetTypeMap(Id pid, String additionalWhereClause) {
        Map<String, String> fieldMap;
        if (null == fieldMap) {
            fieldMap = new Map<String, String>();
            for (
                Field_Mapping__c fm : database.query(
                    'SELECT Salesforce_Field_Name__c, Third_Party_Field_Name__c, Target_Field_Type__c FROM Field_Mapping__c WHERE project__c =: pid ' +
                    CommonIntegrationConstants.MAP_ADDITIONAL_WHERE.get(additionalWhereClause)
                )
            ) {
                fieldMap.put(
                    fm.Salesforce_Field_Name__c.toLowerCase(),
                    (String.isBlank(fm.Target_Field_Type__c) ? '' : fm.Target_Field_Type__c.toLowerCase())
                );
            }
        }
        return fieldMap;
    }
    //Escapes undesired characters in the returned JSON
    public static String escapeInvalidChars(String responseText) {
        responseText = String.escapeSingleQuotes(responseText);
        responseText = responseText.escapeHTML4();
        responseText = responseText.replace('{&quot;', '{"');
        responseText = responseText.replace('&quot;:&quot;', '":"');
        responseText = responseText.replace('&quot;,&quot;', '","');
        responseText = responseText.replace('&quot;:', '":');
        responseText = responseText.replace(',&quot;', ',"');
        responseText = responseText.replace('&quot;}', '"}');
        responseText = responseText.replace('&amp;', '&');
        responseText = responseText.replace('\b', '\\b');
        responseText = responseText.replace('\n', '\\n');
        responseText = responseText.replace('\t', '\\t');
        responseText = responseText.replace('\r', '\\r');
        responseText = responseText.replace('\\', '\\\\');
        return responseText;
    }
    public static String replaceFromCurly(String strwcurly) {
        return strwcurly.replace('lcurly', '{').replace('rcurly', '}');
    }
    public static String escapeDoubleQuotes(String value) {
        return value.replace('"', '\\"');
    }
    public static Date convertLongDateToDate(String longDate) {
        return Date.newInstance(
            Integer.valueOf(longDate.substring(4, 8)),
            Integer.valueOf(longDate.substring(2, 4)),
            Integer.valueOf(longDate.substring(0, 2))
        );
    }
    //method to create logs under related user story or project record based on the step of the integration after all callouts are done
    public static void createLogRecords() {
        if (callOutLogList2Insert.size() > 0) {
            database.insert(callOutLogList2Insert, false);
        }
    }
}