/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class Persona implements copado.CopadoDomain {
    global static copado.Persona.CredentialService CredentialService {
        get;
        set;
    }
    global Persona() {

    }
global class CredentialService implements copado.CopadoService {
    global CredentialService() {

    }
    global void share(copado.Persona.ShareCredentialRequest request) {

    }
}
global class ShareCredentialRequest implements copado.CopadoServiceRequest {
    global List<Id> credentialIds;
    global Id personaId;
    global ShareCredentialRequest() {

    }
}
}
