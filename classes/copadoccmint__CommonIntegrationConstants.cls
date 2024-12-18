public virtual with sharing class CommonIntegrationConstants {
    protected final String DONT_EXCLUDE_FROM_THIRD_PARTY = 'DONT_EXCLUDE_FROM_THIRD_PARTY';
    protected final String DONT_EXCLUDE_FROM_SALESFORCE = 'DONT_EXCLUDE_FROM_SALESFORCE';
    protected final String EMPTY_CHAR = '';
    protected final String ONE_CHAR = ' ';
    protected final String COMMA = ',';
    protected final String FIELD_QUERY_PATH = '&fields=';
    protected final String SPRINT_ID = 'sprintid';
    protected final String PROJECT_ID = 'projectid';
    protected final String EXTERNAL_ID = 'External_Id__c';
    protected final String COPADO_RELEASE = 'copado__release__c';
    protected final String FIELDS_STRING = 'fields';
    protected final String CONTENT_TYPE_HEADER = 'Content-Type:application/json';
    protected final String DEVELOPER_KEYWORD = 'developer';
    protected final String THEME_KEYWORD = 'theme';
    protected final String TEAM_WORD = 'team';
    protected final String ID_KEYWORD = 'id';
    protected final String NAME_KEYWORD = 'name';
    protected final String RECORD_TYPE_ID = 'recordtypeid';
    public final static Map<String, String> MAP_ADDITIONAL_WHERE = new Map<String, String>();
    static {
        MAP_ADDITIONAL_WHERE.put('DONT_EXCLUDE_FROM_THIRD_PARTY', ' and Exclude_from_tpu__c = false');
        MAP_ADDITIONAL_WHERE.put('DONT_EXCLUDE_FROM_SALESFORCE', ' and Exclude_from_su__c = false');
    }
}