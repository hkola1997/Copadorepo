public class CredentialManager {
    // Potential PMD Violation: Hardcoded credentials
    private String username = 'admin';
    private String password = '12345';

    public void logIn() {
        System.debug('Logging in with ' + username + ' and ' + password);
    }
}