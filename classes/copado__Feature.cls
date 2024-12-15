/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class Feature implements copado.CopadoDomain {
    global static copado.Feature.JWTSetting JWTSetting {
        get;
        set;
    }
    global Feature() {

    }
    global static Boolean isApplicationRegistered() {
        return null;
    }
    global static Boolean isAutomateGovOrgEnabled() {
        return null;
    }
    global static Boolean isCCHEnabled() {
        return null;
    }
    global static Boolean isCCMEnabled() {
        return null;
    }
global class JWTSetting implements copado.CopadoService {
    global JWTSetting() {

    }
    global copado.Feature.JWTSettingStatusResult assignPermissionToConnectedApp(copado.Feature.JWTSettingStatusRequest request) {
        return null;
    }
    global copado.Feature.JWTSettingStatusResult assignPermissionToExistingUsers(copado.Feature.JWTSettingStatusRequest request) {
        return null;
    }
    global copado.Feature.JWTSettingStatusResult assignPermissionToPersonas1(copado.Feature.JWTSettingStatusRequest request) {
        return null;
    }
    global copado.Feature.JWTSettingStatusResult assignPermissionToPersonas2(copado.Feature.JWTSettingStatusRequest request) {
        return null;
    }
    global copado.Feature.JWTSettingStatusResult createPermissions() {
        return null;
    }
    global copado.Feature.JWTSettingStatusResult execute(copado.Feature.JWTSettingStatusRequest request) {
        return null;
    }
}
global class JWTSettingStatusRequest implements copado.CopadoServiceRequest {
    global Id permissionSetGroupId;
    global Id permissionSetId;
    global List<Id> userIds;
    global JWTSettingStatusRequest() {

    }
}
global class JWTSettingStatusResult implements copado.CopadoServiceResult {
    global Id permissionSetGroupId;
    global Id permissionSetId;
    global Boolean status;
    global List<Id> userIds;
    global JWTSettingStatusResult() {

    }
}
}
