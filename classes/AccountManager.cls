public class AccountManager {
    public void updateAccount(String accountId, String newName) {
        // Potential PMD Violation: SOQL in loop
        for (Contact c : [SELECT Id, Name FROM Contact WHERE AccountId = :accountId]) {
            c.LastName = newName;
            update c;
        }
    }
}